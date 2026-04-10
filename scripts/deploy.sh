#!/usr/bin/env bash
# ============================================================
# InRiver-DataCase: Intelligent Deployment Script
# Runs pre-flight validation, displays a plan, then executes.
#
# Usage: ./scripts/deploy.sh -g <resource-group> [options]
# ============================================================
set -euo pipefail

# ── Colours ────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Paths ──────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="${ROOT_DIR}/deploy-${TIMESTAMP}.log"

# ── Defaults ───────────────────────────────────────────────
RESOURCE_GROUP=""
LOCATION="swedencentral"
ENV_NAME="dev"
PLAN_FILE=""
SKIP_CONFIRM=false
SKIP_DOCKER=false
SKIP_SEED=false
AI_MODEL_NAME="gpt-5.4"
AI_MODEL_VERSION=""
AI_MODEL_SKU="GlobalStandard"
AI_MODEL_CAPACITY=100

# ── Usage ──────────────────────────────────────────────────
usage() {
    cat <<EOF
${BOLD}InRiver-DataCase — Deployment${NC}

Usage: $(basename "$0") [OPTIONS]

Required:
  -g, --resource-group NAME   Target Azure resource group

Options:
  -l, --location REGION        Azure region (default: swedencentral)
  -e, --env ENV                Environment name: dev|staging|prod (default: dev)
  -p, --plan PATH              Path to existing deployment plan JSON (skip preflight)
  -y, --yes                    Skip confirmation prompt
  --skip-docker                Skip Docker build/push step
  --skip-seed                  Skip database seeding step
  --model NAME                 AI model to deploy (default: gpt-4o)
  --model-version VER          AI model version (default: latest)
  --model-sku SKU              Model SKU: GlobalStandard|Standard (default: GlobalStandard)
  --model-capacity N           Token capacity in K TPM (default: 30)
  -h, --help                   Show this help message

Examples:
  $(basename "$0") -g RG-InRiver
  $(basename "$0") -g RG-InRiver -e dev -y --skip-docker
  $(basename "$0") -g RG-InRiver -p plan.json -y
EOF
    exit 0
}

# ── Parse Arguments ────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        -g|--resource-group) RESOURCE_GROUP="$2"; shift 2 ;;
        -l|--location)       LOCATION="$2"; shift 2 ;;
        -e|--env)            ENV_NAME="$2"; shift 2 ;;
        -p|--plan)           PLAN_FILE="$2"; shift 2 ;;
        -y|--yes)            SKIP_CONFIRM=true; shift ;;
        --skip-docker)       SKIP_DOCKER=true; shift ;;
        --skip-seed)         SKIP_SEED=true; shift ;;
        --model)             AI_MODEL_NAME="$2"; shift 2 ;;
        --model-version)     AI_MODEL_VERSION="$2"; shift 2 ;;
        --model-sku)         AI_MODEL_SKU="$2"; shift 2 ;;
        --model-capacity)    AI_MODEL_CAPACITY="$2"; shift 2 ;;
        -h|--help)           usage ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            usage
            ;;
    esac
done

if [[ -z "${RESOURCE_GROUP}" && -z "${PLAN_FILE}" ]]; then
    echo -e "${RED}Error: --resource-group (-g) is required (or provide --plan).${NC}" >&2
    usage
fi

# ── Logging ────────────────────────────────────────────────
exec > >(tee -a "${LOG_FILE}") 2>&1
echo -e "${BLUE}Log file: ${LOG_FILE}${NC}"

# ── Helper: Step timer ─────────────────────────────────────
step_start() {
    STEP_LABEL="$1"
    STEP_START_TIME=$(date +%s)
    echo ""
    echo -e "${BOLD}${CYAN}▶ ${STEP_LABEL}${NC}"
}

step_done() {
    local elapsed=$(( $(date +%s) - STEP_START_TIME ))
    echo -e "${GREEN}  ✔ ${STEP_LABEL} completed (${elapsed}s)${NC}"
}

step_fail() {
    local msg="${1:-Step failed}"
    local elapsed=$(( $(date +%s) - STEP_START_TIME ))
    echo -e "${RED}  ✖ ${STEP_LABEL} failed after ${elapsed}s${NC}"
    echo -e "${RED}  ${msg}${NC}"
    echo -e "${YELLOW}  Check the log: ${LOG_FILE}${NC}"
    exit 1
}

# ── Step 1: Run or load preflight plan ─────────────────────
DEPLOY_START=$(date +%s)

if [[ -n "${PLAN_FILE}" ]]; then
    # Use existing plan
    if [[ ! -f "${PLAN_FILE}" ]]; then
        echo -e "${RED}Error: Plan file not found: ${PLAN_FILE}${NC}"
        exit 1
    fi
    echo -e "${BLUE}Using existing deployment plan: ${PLAN_FILE}${NC}"
else
    # Run preflight
    step_start "Step 1/5: Pre-flight validation"

    PREFLIGHT_ARGS=(-g "${RESOURCE_GROUP}" -l "${LOCATION}" -e "${ENV_NAME}")
    PLAN_FILE=$(mktemp /tmp/inriver-plan-XXXXXX.json)
    PREFLIGHT_ARGS+=(-o "${PLAN_FILE}")

    if ! bash "${SCRIPT_DIR}/preflight.sh" "${PREFLIGHT_ARGS[@]}"; then
        step_fail "Pre-flight validation failed."
    fi

    step_done
fi

# ── Read plan values ───────────────────────────────────────
RESOURCE_GROUP=$(jq -r '.resourceGroup' "${PLAN_FILE}")
RG_EXISTS=$(jq -r '.resourceGroupExists' "${PLAN_FILE}")
LOCATION=$(jq -r '.location' "${PLAN_FILE}")
ENV_NAME=$(jq -r '.envName' "${PLAN_FILE}")
RESOURCE_PREFIX=$(jq -r '.resourcePrefix' "${PLAN_FILE}")

EXISTING_LOG_ANALYTICS_ID=$(jq -r '.bicepParameters.existingLogAnalyticsId // ""' "${PLAN_FILE}")
EXISTING_APP_INSIGHTS_ID=$(jq -r '.bicepParameters.existingAppInsightsId // ""' "${PLAN_FILE}")
EXISTING_STORAGE_ID=$(jq -r '.bicepParameters.existingStorageId // ""' "${PLAN_FILE}")
EXISTING_AI_PROJECT_ID=$(jq -r '.bicepParameters.existingAiProjectId // ""' "${PLAN_FILE}")

SQLCMD_OK=$(jq -r '.toolAvailability.sqlcmd // false' "${PLAN_FILE}")
DOCKER_OK=$(jq -r '.toolAvailability.docker // false' "${PLAN_FILE}")

# ── Confirmation ───────────────────────────────────────────
if [[ "${SKIP_CONFIRM}" != "true" ]]; then
    echo ""
    echo -ne "${YELLOW}${BOLD}Proceed with deployment? [y/N] ${NC}"
    read -r answer
    if [[ "${answer}" != "y" && "${answer}" != "Y" ]]; then
        echo -e "${YELLOW}Aborted.${NC}"
        exit 0
    fi
fi

# ── Step 2: Ensure resource group exists ───────────────────
step_start "Step 2/5: Ensure resource group"

if [[ "${RG_EXISTS}" == "true" ]]; then
    echo -e "  ${GREEN}♻️  Reusing existing resource group: ${RESOURCE_GROUP}${NC}"
else
    echo -e "  🆕 Creating resource group: ${RESOURCE_GROUP} in ${LOCATION}"
    if ! az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}" --output none; then
        step_fail "Failed to create resource group."
    fi
fi

step_done

# ── Step 3: Deploy Bicep infrastructure ────────────────────
step_start "Step 3/5: Deploy Bicep infrastructure"

echo -e "  ${BLUE}This may take several minutes...${NC}"

# Get current user's Entra ID info for SQL AD-only admin
echo -e "  Resolving Entra ID admin for Azure SQL..."
SQL_ADMIN_OID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")
SQL_ADMIN_NAME=$(az ad signed-in-user show --query displayName -o tsv 2>/dev/null || echo "SQL Admin")

if [[ -z "${SQL_ADMIN_OID}" ]]; then
    step_fail "Could not resolve your Entra ID object ID. Ensure you're logged in with 'az login'."
fi
echo -e "  SQL Entra Admin: ${SQL_ADMIN_NAME} (${SQL_ADMIN_OID})"

BICEP_PARAMS=(
    --parameters "envName=${ENV_NAME}"
    --parameters "location=${LOCATION}"
    --parameters "sqlEntraAdminObjectId=${SQL_ADMIN_OID}"
    --parameters "sqlEntraAdminDisplayName=${SQL_ADMIN_NAME}"
    --parameters "sqlEntraAdminPrincipalType=User"
)

# Pass existing resource IDs so Bicep can reuse them
if [[ -n "${EXISTING_LOG_ANALYTICS_ID}" ]]; then
    BICEP_PARAMS+=(--parameters "existingLogAnalyticsId=${EXISTING_LOG_ANALYTICS_ID}")
fi
if [[ -n "${EXISTING_APP_INSIGHTS_ID}" ]]; then
    BICEP_PARAMS+=(--parameters "existingAppInsightsId=${EXISTING_APP_INSIGHTS_ID}")
fi
if [[ -n "${EXISTING_STORAGE_ID}" ]]; then
    BICEP_PARAMS+=(--parameters "existingStorageId=${EXISTING_STORAGE_ID}")
fi
if [[ -n "${EXISTING_AI_PROJECT_ID}" ]]; then
    BICEP_PARAMS+=(--parameters "existingAiProjectId=${EXISTING_AI_PROJECT_ID}")
fi

# AI Model deployment parameters
BICEP_PARAMS+=(--parameters "aiModelName=${AI_MODEL_NAME}")
if [[ -n "${AI_MODEL_VERSION}" ]]; then
    BICEP_PARAMS+=(--parameters "aiModelVersion=${AI_MODEL_VERSION}")
fi
BICEP_PARAMS+=(--parameters "aiModelSkuName=${AI_MODEL_SKU}")
BICEP_PARAMS+=(--parameters "aiModelCapacity=${AI_MODEL_CAPACITY}")

DEPLOY_OUTPUT=$(az deployment group create \
    --resource-group "${RESOURCE_GROUP}" \
    --template-file "${ROOT_DIR}/infra/main.bicep" \
    "${BICEP_PARAMS[@]}" \
    --query 'properties.outputs' \
    --output json 2>&1) || step_fail "Bicep deployment failed. Review the log for details.\n  Rollback: Resources are left in place. Re-run after fixing the template."

ACR_LOGIN_SERVER=$(echo "${DEPLOY_OUTPUT}" | jq -r '.acrLoginServer.value // empty')
SQL_SERVER_FQDN=$(echo "${DEPLOY_OUTPUT}" | jq -r '.sqlServerFqdn.value // empty')
FRONTEND_URL=$(echo "${DEPLOY_OUTPUT}" | jq -r '.frontendUrl.value // empty')
BACKEND_URL=$(echo "${DEPLOY_OUTPUT}" | jq -r '.backendUrl.value // empty')
KEY_VAULT_NAME=$(echo "${DEPLOY_OUTPUT}" | jq -r '.keyVaultName.value // empty')
IDENTITY_CLIENT_ID=$(echo "${DEPLOY_OUTPUT}" | jq -r '.identityClientId.value // empty')
MODEL_DEPLOYMENT=$(echo "${DEPLOY_OUTPUT}" | jq -r '.modelDeploymentName.value // empty')
AI_ENDPOINT=$(echo "${DEPLOY_OUTPUT}" | jq -r '.aiProjectEndpoint.value // empty')

echo -e "  ACR:      ${ACR_LOGIN_SERVER:-N/A}"
echo -e "  SQL:      ${SQL_SERVER_FQDN:-N/A}"
echo -e "  Frontend: ${FRONTEND_URL:-N/A}"
echo -e "  Backend:  ${BACKEND_URL:-N/A}"

step_done

# ── Step 4: Build and push Docker images ───────────────────
step_start "Step 4/5: Build and push Docker images"

if [[ "${SKIP_DOCKER}" == "true" ]]; then
    echo -e "  ${YELLOW}⏭  Skipped (--skip-docker)${NC}"
elif [[ "${DOCKER_OK}" == "false" ]]; then
    echo -e "  ${YELLOW}⏭  Skipped (Docker not available)${NC}"
elif [[ -z "${ACR_LOGIN_SERVER}" ]]; then
    echo -e "  ${YELLOW}⏭  Skipped (no ACR login server in deployment outputs)${NC}"
else
    ACR_NAME="${ACR_LOGIN_SERVER%%.*}"
    echo -e "  Logging in to ACR: ${ACR_NAME}"
    az acr login --name "${ACR_NAME}" || step_fail "ACR login failed."

    # Backend
    if [[ -f "${ROOT_DIR}/backend/Dockerfile" ]]; then
        echo -e "  Building backend image..."
        docker build -t "${ACR_LOGIN_SERVER}/${RESOURCE_PREFIX}-api:latest" "${ROOT_DIR}/backend" \
            || step_fail "Backend Docker build failed."
        echo -e "  Pushing backend image..."
        docker push "${ACR_LOGIN_SERVER}/${RESOURCE_PREFIX}-api:latest" \
            || step_fail "Backend Docker push failed."
    else
        echo -e "  ${YELLOW}SKIP: backend/Dockerfile not found${NC}"
    fi

    # Frontend
    if [[ -f "${ROOT_DIR}/frontend/Dockerfile" ]]; then
        echo -e "  Building frontend image..."
        docker build -t "${ACR_LOGIN_SERVER}/${RESOURCE_PREFIX}-frontend:latest" "${ROOT_DIR}/frontend" \
            || step_fail "Frontend Docker build failed."
        echo -e "  Pushing frontend image..."
        docker push "${ACR_LOGIN_SERVER}/${RESOURCE_PREFIX}-frontend:latest" \
            || step_fail "Frontend Docker push failed."
    else
        echo -e "  ${YELLOW}SKIP: frontend/Dockerfile not found${NC}"
    fi
fi

step_done

# ── Step 5: Seed databases ────────────────────────────────
step_start "Step 5/5: Seed databases"

# Ensure sqlcmd is on PATH (mssql-tools18 installs to /opt/)
for _tools_dir in /opt/mssql-tools18/bin /opt/mssql-tools/bin; do
    [[ -x "${_tools_dir}/sqlcmd" ]] && export PATH="${_tools_dir}:${PATH}" && break
done

if [[ "${SKIP_SEED}" == "true" ]]; then
    echo -e "  ${YELLOW}⏭  Skipped (--skip-seed)${NC}"
elif [[ "${SQLCMD_OK}" == "false" ]]; then
    echo -e "  ${YELLOW}⏭  Skipped (sqlcmd not available)${NC}"
elif [[ -z "${SQL_SERVER_FQDN}" ]]; then
    echo -e "  ${YELLOW}⏭  Skipped (no SQL server FQDN in deployment outputs)${NC}"
else
    "${SCRIPT_DIR}/seed-databases.sh" "${SQL_SERVER_FQDN}" \
        || step_fail "Database seeding failed. Databases exist but may be empty.\n  Re-run with: ./scripts/seed-databases.sh ${SQL_SERVER_FQDN}"
fi

step_done

# ── Summary ────────────────────────────────────────────────
TOTAL_ELAPSED=$(( $(date +%s) - DEPLOY_START ))
MINUTES=$(( TOTAL_ELAPSED / 60 ))
SECONDS_REM=$(( TOTAL_ELAPSED % 60 ))

echo ""
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN} Deployment Complete${NC}"
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════${NC}"
echo -e " Resource Group:    ${BOLD}${RESOURCE_GROUP}${NC}"
echo -e " Environment:       ${BOLD}${ENV_NAME}${NC}"
echo -e " ACR Login Server:  ${BOLD}${ACR_LOGIN_SERVER:-N/A}${NC}"
echo -e " SQL Server FQDN:   ${BOLD}${SQL_SERVER_FQDN:-N/A}${NC}"
echo -e " Frontend URL:      ${BOLD}${FRONTEND_URL:-N/A}${NC}"
echo -e " Backend URL:       ${BOLD}${BACKEND_URL:-N/A}${NC}"
echo -e " Key Vault:         ${BOLD}${KEY_VAULT_NAME:-N/A}${NC}"
echo -e " Identity Client:   ${BOLD}${IDENTITY_CLIENT_ID:-N/A}${NC}"
echo -e " AI Foundry:        ${BOLD}${AI_ENDPOINT:-N/A}${NC}"
echo -e " Model Deployment:  ${BOLD}${MODEL_DEPLOYMENT:-${AI_MODEL_NAME}}${NC}"
echo -e " Total time:        ${BOLD}${MINUTES}m ${SECONDS_REM}s${NC}"
echo -e " Log file:          ${BOLD}${LOG_FILE}${NC}"
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  • View resources:  az resource list -g ${RESOURCE_GROUP} -o table"
echo -e "  • Teardown PoC:    ./scripts/teardown.sh -g ${RESOURCE_GROUP}"
echo -e "  • Re-run deploy:   ./scripts/deploy.sh -g ${RESOURCE_GROUP} -p ${PLAN_FILE} -y"
