#!/usr/bin/env bash
# ============================================================
# InRiver-DataCase: Pre-Flight Validation & Deployment Plan
# Scans an Azure resource group, identifies existing resources,
# and generates a deployment plan for the Bicep infrastructure.
#
# Usage: ./scripts/preflight.sh -g <resource-group> [options]
# ============================================================
set -euo pipefail

# ── Colours & Symbols ──────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Colour

check_mark="${GREEN}✅${NC}"
cross_mark="${RED}❌${NC}"
warn_mark="${YELLOW}⚠️${NC}"
recycle_mark="♻️ "
new_mark="🆕"

# ── Defaults ───────────────────────────────────────────────
RESOURCE_GROUP=""
LOCATION="swedencentral"
ENV_NAME="dev"
OUTPUT_PLAN=""

# ── Usage ──────────────────────────────────────────────────
usage() {
    cat <<EOF
${BOLD}InRiver-DataCase — Pre-Flight Validation${NC}

Usage: $(basename "$0") [OPTIONS]

Required:
  -g, --resource-group NAME   Target Azure resource group

Options:
  -l, --location REGION        Azure region (default: swedencentral)
  -e, --env ENV                Environment name: dev|staging|prod (default: dev)
  -o, --output-plan PATH       Write deployment plan JSON to this path
  -h, --help                   Show this help message

Examples:
  $(basename "$0") -g RG-InRiver
  $(basename "$0") -g RG-InRiver -l swedencentral -e dev -o plan.json
EOF
    exit 0
}

# ── Parse Arguments ────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        -g|--resource-group) RESOURCE_GROUP="$2"; shift 2 ;;
        -l|--location)       LOCATION="$2"; shift 2 ;;
        -e|--env)            ENV_NAME="$2"; shift 2 ;;
        -o|--output-plan)    OUTPUT_PLAN="$2"; shift 2 ;;
        -h|--help)           usage ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            usage
            ;;
    esac
done

if [[ -z "${RESOURCE_GROUP}" ]]; then
    echo -e "${RED}Error: --resource-group (-g) is required.${NC}" >&2
    usage
fi

RESOURCE_PREFIX="inriver-${ENV_NAME}"

# ── Helper: check a CLI tool ──────────────────────────────
require_tool() {
    local tool="$1"
    local required="${2:-true}"
    if command -v "$tool" &>/dev/null; then
        echo -e "  ${check_mark} ${tool} found"
        return 0
    elif [[ "$required" == "true" ]]; then
        echo -e "  ${cross_mark} ${tool} is ${RED}required${NC} but not found. Please install it."
        exit 1
    else
        echo -e "  ${warn_mark} ${tool} not found (optional — some steps will be skipped)"
        return 1
    fi
}

# ── Step 1: Validate Prerequisites ────────────────────────
echo ""
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════${NC}"
echo -e "${BOLD} InRiver-DataCase — Pre-Flight Checks${NC}"
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Checking prerequisites...${NC}"

require_tool "az"
require_tool "jq"

# Check az bicep
if az bicep version &>/dev/null; then
    echo -e "  ${check_mark} az bicep available"
else
    echo -e "  ${cross_mark} az bicep is ${RED}required${NC}. Run: az bicep install"
    exit 1
fi

# Check Azure login
if az account show &>/dev/null; then
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    echo -e "  ${check_mark} Logged in to Azure — subscription: ${BOLD}${SUBSCRIPTION_NAME}${NC}"
else
    echo -e "  ${cross_mark} Not logged in to Azure. Run: ${BOLD}az login${NC}"
    exit 1
fi

# Optional tools
SQLCMD_AVAILABLE=false
DOCKER_AVAILABLE=false

if command -v sqlcmd &>/dev/null; then
    echo -e "  ${check_mark} sqlcmd found"
    SQLCMD_AVAILABLE=true
elif [[ -x /opt/mssql-tools18/bin/sqlcmd ]]; then
    export PATH="/opt/mssql-tools18/bin:${PATH}"
    echo -e "  ${check_mark} sqlcmd found at /opt/mssql-tools18/bin"
    SQLCMD_AVAILABLE=true
elif [[ -x /opt/mssql-tools/bin/sqlcmd ]]; then
    export PATH="/opt/mssql-tools/bin:${PATH}"
    echo -e "  ${check_mark} sqlcmd found at /opt/mssql-tools/bin"
    SQLCMD_AVAILABLE=true
else
    echo -e "  ${warn_mark} sqlcmd not found (database seeding will be skipped)"
    echo -e "    Rebuild the DevContainer to install it automatically."
fi

require_tool "docker" "false" && DOCKER_AVAILABLE=true

# ── Step 2: Check Resource Group ──────────────────────────
echo ""
echo -e "${BLUE}Checking resource group: ${BOLD}${RESOURCE_GROUP}${NC}"

RG_EXISTS=false
if az group show --name "${RESOURCE_GROUP}" &>/dev/null; then
    RG_EXISTS=true
    RG_LOCATION=$(az group show --name "${RESOURCE_GROUP}" --query location -o tsv)
    echo -e "  ${check_mark} Resource group exists in ${BOLD}${RG_LOCATION}${NC} — will reuse"
    # Use the RG's actual location if it already exists
    LOCATION="${RG_LOCATION}"
else
    echo -e "  ${cross_mark} Resource group does not exist — will create at ${BOLD}${LOCATION}${NC}"
fi

# ── Step 3: Scan Existing Resources ───────────────────────
echo ""
echo -e "${BLUE}Scanning existing resources...${NC}"

declare -A RESOURCE_IDS
declare -A RESOURCE_NAMES
RESOURCE_TYPES=(
    "logAnalytics"
    "appInsights"
    "storage"
    "aiProject"
    "aiServices"
    "acr"
    "sqlServer"
    "keyVault"
    "containerAppsEnv"
    "identity"
)
RESOURCE_LABELS=(
    "Log Analytics Workspace"
    "Application Insights"
    "Storage Account"
    "AI Foundry Project"
    "AI Services"
    "Container Registry"
    "SQL Server"
    "Key Vault"
    "Container Apps Environment"
    "Managed Identity"
)

# Initialise all to empty
for rt in "${RESOURCE_TYPES[@]}"; do
    RESOURCE_IDS[$rt]=""
    RESOURCE_NAMES[$rt]=""
done

if [[ "${RG_EXISTS}" == "true" ]]; then
    # Log Analytics
    RESOURCE_IDS[logAnalytics]=$(az monitor log-analytics workspace list -g "${RESOURCE_GROUP}" --query "[0].id" -o tsv 2>/dev/null || true)
    RESOURCE_NAMES[logAnalytics]=$(az monitor log-analytics workspace list -g "${RESOURCE_GROUP}" --query "[0].name" -o tsv 2>/dev/null || true)

    # Application Insights
    RESOURCE_IDS[appInsights]=$(az monitor app-insights component list -g "${RESOURCE_GROUP}" --query "[0].id" -o tsv 2>/dev/null || true)
    RESOURCE_NAMES[appInsights]=$(az monitor app-insights component list -g "${RESOURCE_GROUP}" --query "[0].name" -o tsv 2>/dev/null || true)

    # Storage Account
    RESOURCE_IDS[storage]=$(az storage account list -g "${RESOURCE_GROUP}" --query "[0].id" -o tsv 2>/dev/null || true)
    RESOURCE_NAMES[storage]=$(az storage account list -g "${RESOURCE_GROUP}" --query "[0].name" -o tsv 2>/dev/null || true)

    # AI Foundry / AI Project (using az resource to avoid ml extension dependency)
    RESOURCE_IDS[aiProject]=$(az resource list -g "${RESOURCE_GROUP}" --resource-type "Microsoft.MachineLearningServices/workspaces" --query "[?kind=='Project'] | [0].id" -o tsv 2>/dev/null || true)
    RESOURCE_NAMES[aiProject]=$(az resource list -g "${RESOURCE_GROUP}" --resource-type "Microsoft.MachineLearningServices/workspaces" --query "[?kind=='Project'] | [0].name" -o tsv 2>/dev/null || true)

    # AI Services (Cognitive Services)
    RESOURCE_IDS[aiServices]=$(az cognitiveservices account list -g "${RESOURCE_GROUP}" --query "[0].id" -o tsv 2>/dev/null || true)
    RESOURCE_NAMES[aiServices]=$(az cognitiveservices account list -g "${RESOURCE_GROUP}" --query "[0].name" -o tsv 2>/dev/null || true)

    # Container Registry
    RESOURCE_IDS[acr]=$(az acr list -g "${RESOURCE_GROUP}" --query "[0].id" -o tsv 2>/dev/null || true)
    RESOURCE_NAMES[acr]=$(az acr list -g "${RESOURCE_GROUP}" --query "[0].name" -o tsv 2>/dev/null || true)

    # SQL Server
    RESOURCE_IDS[sqlServer]=$(az sql server list -g "${RESOURCE_GROUP}" --query "[0].id" -o tsv 2>/dev/null || true)
    RESOURCE_NAMES[sqlServer]=$(az sql server list -g "${RESOURCE_GROUP}" --query "[0].name" -o tsv 2>/dev/null || true)

    # Key Vault
    RESOURCE_IDS[keyVault]=$(az keyvault list -g "${RESOURCE_GROUP}" --query "[0].id" -o tsv 2>/dev/null || true)
    RESOURCE_NAMES[keyVault]=$(az keyvault list -g "${RESOURCE_GROUP}" --query "[0].name" -o tsv 2>/dev/null || true)

    # Container Apps Environment
    RESOURCE_IDS[containerAppsEnv]=$(az containerapp env list -g "${RESOURCE_GROUP}" --query "[0].id" -o tsv 2>/dev/null || true)
    RESOURCE_NAMES[containerAppsEnv]=$(az containerapp env list -g "${RESOURCE_GROUP}" --query "[0].name" -o tsv 2>/dev/null || true)

    # Managed Identity
    RESOURCE_IDS[identity]=$(az identity list -g "${RESOURCE_GROUP}" --query "[0].id" -o tsv 2>/dev/null || true)
    RESOURCE_NAMES[identity]=$(az identity list -g "${RESOURCE_GROUP}" --query "[0].name" -o tsv 2>/dev/null || true)
fi

# ── Step 4: Display the Deployment Plan ───────────────────
echo ""
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════${NC}"
echo -e "${BOLD} InRiver-DataCase — Deployment Plan${NC}"
if [[ "${RG_EXISTS}" == "true" ]]; then
    echo -e " Resource Group: ${BOLD}${RESOURCE_GROUP}${NC} (existing)"
else
    echo -e " Resource Group: ${BOLD}${RESOURCE_GROUP}${NC} (${YELLOW}will create${NC})"
fi
echo -e " Location:       ${BOLD}${LOCATION}${NC}"
echo -e " Environment:    ${BOLD}${ENV_NAME}${NC}"
echo -e " Subscription:   ${BOLD}${SUBSCRIPTION_NAME}${NC}"
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════${NC}"

echo ""
echo -e "${BOLD}Resource Inventory:${NC}"

# Default names for resources that will be created
declare -A DEFAULT_NAMES
DEFAULT_NAMES[logAnalytics]="${RESOURCE_PREFIX}-log"
DEFAULT_NAMES[appInsights]="${RESOURCE_PREFIX}-ai"
DEFAULT_NAMES[storage]="${RESOURCE_PREFIX//-/}stor"
DEFAULT_NAMES[aiProject]="${RESOURCE_PREFIX}-aiproject"
DEFAULT_NAMES[aiServices]="${RESOURCE_PREFIX}-aisvc"
DEFAULT_NAMES[acr]="${RESOURCE_PREFIX//-/}acr"
DEFAULT_NAMES[sqlServer]="${RESOURCE_PREFIX}-sql"
DEFAULT_NAMES[keyVault]="${RESOURCE_PREFIX//-/}kv"
DEFAULT_NAMES[containerAppsEnv]="${RESOURCE_PREFIX}-cae"
DEFAULT_NAMES[identity]="${RESOURCE_PREFIX}-identity"

for i in "${!RESOURCE_TYPES[@]}"; do
    rt="${RESOURCE_TYPES[$i]}"
    label="${RESOURCE_LABELS[$i]}"
    rid="${RESOURCE_IDS[$rt]}"

    # Pad the label for alignment
    padded_label=$(printf '%-28s' "$label")

    if [[ -n "$rid" ]]; then
        echo -e "  ${check_mark} ${padded_label} ${GREEN}FOUND${NC}    ${rid}"
    else
        echo -e "  ${cross_mark} ${padded_label} ${RED}MISSING${NC}  → will create: ${BOLD}${DEFAULT_NAMES[$rt]}${NC}"
    fi
done

# ── Deployment Actions ─────────────────────────────────────
echo ""
echo -e "${BOLD}Deployment Actions:${NC}"
action_num=0

if [[ "${RG_EXISTS}" != "true" ]]; then
    action_num=$((action_num + 1))
    echo -e "  ${action_num}. ${new_mark} Create resource group ${BOLD}${RESOURCE_GROUP}${NC} in ${LOCATION}"
fi

for i in "${!RESOURCE_TYPES[@]}"; do
    rt="${RESOURCE_TYPES[$i]}"
    label="${RESOURCE_LABELS[$i]}"
    rid="${RESOURCE_IDS[$rt]}"
    action_num=$((action_num + 1))

    if [[ -n "$rid" ]]; then
        echo -e "  ${action_num}. ${recycle_mark} Reuse existing ${label}"
    else
        detail=""
        case "$rt" in
            acr)               detail=" (Basic SKU)" ;;
            sqlServer)         detail=" + 3 tenant databases" ;;
            containerAppsEnv)  detail=" + 2 container apps" ;;
            *)                 detail="" ;;
        esac
        echo -e "  ${action_num}. ${new_mark} Create ${label}${detail}"
    fi
done

# Count new resources
new_count=0
for rt in "${RESOURCE_TYPES[@]}"; do
    if [[ -z "${RESOURCE_IDS[$rt]}" ]]; then
        new_count=$((new_count + 1))
    fi
done

echo ""
if [[ "${new_count}" -eq 0 ]]; then
    echo -e "  ${GREEN}All resources already exist. Bicep will reconcile state.${NC}"
else
    echo -e "  ${BLUE}Estimated monthly cost (new resources): ~\$25-45${NC}"
fi

if [[ "${SQLCMD_AVAILABLE}" == "false" ]]; then
    echo -e "  ${warn_mark} sqlcmd not available — database seeding will be skipped"
fi
if [[ "${DOCKER_AVAILABLE}" == "false" ]]; then
    echo -e "  ${warn_mark} Docker not available — image build/push will be skipped"
fi

echo -e "${BOLD}${CYAN}══════════════════════════════════════════════${NC}"

# ── Step 5: Build and Write Deployment Plan JSON ──────────
PLAN_JSON=$(jq -n \
    --arg rg "${RESOURCE_GROUP}" \
    --argjson rg_exists "${RG_EXISTS}" \
    --arg location "${LOCATION}" \
    --arg env_name "${ENV_NAME}" \
    --arg sub_id "${SUBSCRIPTION_ID}" \
    --arg sub_name "${SUBSCRIPTION_NAME}" \
    --arg prefix "${RESOURCE_PREFIX}" \
    --arg log_id "${RESOURCE_IDS[logAnalytics]}" \
    --arg ai_id "${RESOURCE_IDS[appInsights]}" \
    --arg stor_id "${RESOURCE_IDS[storage]}" \
    --arg proj_id "${RESOURCE_IDS[aiProject]}" \
    --arg aisvc_id "${RESOURCE_IDS[aiServices]}" \
    --arg acr_id "${RESOURCE_IDS[acr]}" \
    --arg sql_id "${RESOURCE_IDS[sqlServer]}" \
    --arg kv_id "${RESOURCE_IDS[keyVault]}" \
    --arg cae_id "${RESOURCE_IDS[containerAppsEnv]}" \
    --arg ident_id "${RESOURCE_IDS[identity]}" \
    --arg log_name "${RESOURCE_NAMES[logAnalytics]}" \
    --arg ai_name "${RESOURCE_NAMES[appInsights]}" \
    --arg stor_name "${RESOURCE_NAMES[storage]}" \
    --arg proj_name "${RESOURCE_NAMES[aiProject]}" \
    --arg aisvc_name "${RESOURCE_NAMES[aiServices]}" \
    --arg acr_name "${RESOURCE_NAMES[acr]}" \
    --arg sql_name "${RESOURCE_NAMES[sqlServer]}" \
    --arg kv_name "${RESOURCE_NAMES[keyVault]}" \
    --arg cae_name "${RESOURCE_NAMES[containerAppsEnv]}" \
    --arg ident_name "${RESOURCE_NAMES[identity]}" \
    --argjson sqlcmd_ok "${SQLCMD_AVAILABLE}" \
    --argjson docker_ok "${DOCKER_AVAILABLE}" \
    '{
        resourceGroup: $rg,
        resourceGroupExists: $rg_exists,
        location: $location,
        envName: $env_name,
        subscriptionId: $sub_id,
        subscriptionName: $sub_name,
        resourcePrefix: $prefix,
        toolAvailability: {
            sqlcmd: $sqlcmd_ok,
            docker: $docker_ok
        },
        existingResources: {
            logAnalyticsId: $log_id,
            appInsightsId: $ai_id,
            storageId: $stor_id,
            aiProjectId: $proj_id,
            aiServicesId: $aisvc_id,
            acrId: $acr_id,
            sqlServerId: $sql_id,
            keyVaultId: $kv_id,
            containerAppsEnvId: $cae_id,
            identityId: $ident_id
        },
        existingResourceNames: {
            logAnalytics: $log_name,
            appInsights: $ai_name,
            storage: $stor_name,
            aiProject: $proj_name,
            aiServices: $aisvc_name,
            acr: $acr_name,
            sqlServer: $sql_name,
            keyVault: $kv_name,
            containerAppsEnv: $cae_name,
            identity: $ident_name
        },
        bicepParameters: {
            existingLogAnalyticsId: $log_id,
            existingAppInsightsId: $ai_id,
            existingStorageId: $stor_id,
            existingAiProjectId: $proj_id
        }
    }')

# Write plan to file
if [[ -n "${OUTPUT_PLAN}" ]]; then
    PLAN_FILE="${OUTPUT_PLAN}"
else
    PLAN_FILE=$(mktemp /tmp/inriver-plan-XXXXXX.json)
fi

echo "${PLAN_JSON}" > "${PLAN_FILE}"
echo ""
echo -e "${GREEN}Deployment plan written to: ${BOLD}${PLAN_FILE}${NC}"
echo ""

# Output the plan path on stdout last line so deploy.sh can capture it
echo "PLAN_FILE=${PLAN_FILE}"
