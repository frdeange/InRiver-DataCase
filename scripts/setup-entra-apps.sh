#!/usr/bin/env bash
# ============================================================
# InRiver-DataCase: Entra ID App Registration Setup
# Creates SPA + API app registrations, scopes, app roles,
# and updates Container Apps env vars with the resulting IDs.
#
# Usage: ./scripts/setup-entra-apps.sh -g <resource-group> [options]
# ============================================================
set -euo pipefail

# ── Colours ────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ── Defaults ───────────────────────────────────────────────
RESOURCE_GROUP=""
ENV_NAME="dev"
FRONTEND_FQDN=""
BACKEND_FQDN=""

usage() {
    cat <<EOF
${BOLD}InRiver-DataCase — Entra ID App Setup${NC}

Usage: $(basename "$0") [OPTIONS]

Required:
  -g, --resource-group NAME   Azure resource group (to look up Container Apps)

Options:
  -e, --env ENV               Environment name (default: dev)
  -h, --help                  Show this help

EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -g|--resource-group) RESOURCE_GROUP="$2"; shift 2 ;;
        -e|--env)            ENV_NAME="$2"; shift 2 ;;
        -h|--help)           usage ;;
        *)                   echo -e "${RED}Unknown option: $1${NC}"; usage ;;
    esac
done

if [[ -z "${RESOURCE_GROUP}" ]]; then
    echo -e "${RED}Error: --resource-group (-g) is required.${NC}"
    exit 1
fi

RESOURCE_PREFIX="inriver-${ENV_NAME}"
TENANT_ID=$(az account show --query tenantId -o tsv)

echo -e "${BOLD}${BLUE}══════════════════════════════════════════════${NC}"
echo -e "${BOLD} InRiver-DataCase — Entra ID Setup${NC}"
echo -e "${BOLD}${BLUE}══════════════════════════════════════════════${NC}"
echo -e " Resource Group: ${BOLD}${RESOURCE_GROUP}${NC}"
echo -e " Tenant ID:      ${BOLD}${TENANT_ID}${NC}"
echo ""

# ── Step 1: Discover Container App URLs ────────────────────
echo -e "${BLUE}[1/6] Discovering Container App URLs...${NC}"

FRONTEND_FQDN=$(az containerapp show \
    -n "${RESOURCE_PREFIX}-frontend" \
    -g "${RESOURCE_GROUP}" \
    --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null || echo "")

BACKEND_FQDN=$(az containerapp show \
    -n "${RESOURCE_PREFIX}-api" \
    -g "${RESOURCE_GROUP}" \
    --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null || echo "")

echo -e "  Frontend: ${FRONTEND_FQDN:-NOT FOUND}"
echo -e "  Backend:  ${BACKEND_FQDN:-NOT FOUND}"

# ── Step 2: Create API App Registration ────────────────────
echo ""
echo -e "${BLUE}[2/6] Creating API app registration...${NC}"

API_APP_NAME="${RESOURCE_PREFIX}-api"

# Check if it already exists
EXISTING_API_APP=$(az ad app list --display-name "${API_APP_NAME}" --query "[0].appId" -o tsv 2>/dev/null || echo "")

if [[ -n "${EXISTING_API_APP}" ]]; then
    API_CLIENT_ID="${EXISTING_API_APP}"
    echo -e "  ${GREEN}♻️  Already exists:${NC} ${API_CLIENT_ID}"
else
    API_CLIENT_ID=$(az ad app create \
        --display-name "${API_APP_NAME}" \
        --sign-in-audience "AzureADMyOrg" \
        --query appId -o tsv)
    echo -e "  ${GREEN}✅ Created:${NC} ${API_CLIENT_ID}"
fi

API_OBJECT_ID=$(az ad app show --id "${API_CLIENT_ID}" --query id -o tsv)

# ── Step 3: Configure API scope + app roles ────────────────
echo ""
echo -e "${BLUE}[3/6] Configuring API scope and app roles...${NC}"

# Set the Application ID URI
API_ID_URI="api://${API_CLIENT_ID}"
az ad app update --id "${API_CLIENT_ID}" \
    --identifier-uris "${API_ID_URI}" \
    --output none 2>/dev/null || true
echo -e "  API URI: ${API_ID_URI}"

# Expose a scope: Query.Execute
# Use Microsoft Graph API to set oauth2PermissionScopes
SCOPE_ID=$(python3 -c "import uuid; print(uuid.uuid4())")

az rest --method PATCH \
    --uri "https://graph.microsoft.com/v1.0/applications/${API_OBJECT_ID}" \
    --headers 'Content-Type=application/json' \
    --body "{
        \"api\": {
            \"oauth2PermissionScopes\": [
                {
                    \"id\": \"${SCOPE_ID}\",
                    \"adminConsentDisplayName\": \"Execute queries\",
                    \"adminConsentDescription\": \"Allows the app to execute data queries on behalf of the user\",
                    \"userConsentDisplayName\": \"Execute queries\",
                    \"userConsentDescription\": \"Allow the app to query data on your behalf\",
                    \"value\": \"Query.Execute\",
                    \"type\": \"User\",
                    \"isEnabled\": true
                }
            ]
        }
    }" --output none 2>/dev/null || echo -e "  ${YELLOW}⚠  Scope may already exist${NC}"
echo -e "  ${GREEN}✅${NC} Scope: Query.Execute"

# Create App Roles for tenant mapping
az rest --method PATCH \
    --uri "https://graph.microsoft.com/v1.0/applications/${API_OBJECT_ID}" \
    --headers 'Content-Type=application/json' \
    --body "{
        \"appRoles\": [
            {
                \"id\": \"$(python3 -c "import uuid; print(uuid.uuid4())")\",
                \"displayName\": \"Acme Corp User\",
                \"description\": \"Access to Acme Corp (db-acme) data\",
                \"value\": \"Tenant.Acme\",
                \"allowedMemberTypes\": [\"User\"],
                \"isEnabled\": true
            },
            {
                \"id\": \"$(python3 -c "import uuid; print(uuid.uuid4())")\",
                \"displayName\": \"Nova Industries User\",
                \"description\": \"Access to Nova Industries (db-nova) data\",
                \"value\": \"Tenant.Nova\",
                \"allowedMemberTypes\": [\"User\"],
                \"isEnabled\": true
            },
            {
                \"id\": \"$(python3 -c "import uuid; print(uuid.uuid4())")\",
                \"displayName\": \"Apex Solutions User\",
                \"description\": \"Access to Apex Solutions (db-apex) data\",
                \"value\": \"Tenant.Apex\",
                \"allowedMemberTypes\": [\"User\"],
                \"isEnabled\": true
            },
            {
                \"id\": \"$(python3 -c "import uuid; print(uuid.uuid4())")\",
                \"displayName\": \"Administrator\",
                \"description\": \"Admin access to all tenant databases\",
                \"value\": \"Admin\",
                \"allowedMemberTypes\": [\"User\"],
                \"isEnabled\": true
            }
        ]
    }" --output none
echo -e "  ${GREEN}✅${NC} App Roles: Tenant.Acme, Tenant.Nova, Tenant.Apex, Admin"

# Ensure service principal exists for the API app
az ad sp show --id "${API_CLIENT_ID}" --query appId -o tsv 2>/dev/null || \
    az ad sp create --id "${API_CLIENT_ID}" --output none 2>/dev/null
echo -e "  ${GREEN}✅${NC} Service principal ensured"

# ── Step 4: Create SPA App Registration ────────────────────
echo ""
echo -e "${BLUE}[4/6] Creating SPA app registration...${NC}"

SPA_APP_NAME="${RESOURCE_PREFIX}-spa"

EXISTING_SPA_APP=$(az ad app list --display-name "${SPA_APP_NAME}" --query "[0].appId" -o tsv 2>/dev/null || echo "")

if [[ -n "${EXISTING_SPA_APP}" ]]; then
    SPA_CLIENT_ID="${EXISTING_SPA_APP}"
    echo -e "  ${GREEN}♻️  Already exists:${NC} ${SPA_CLIENT_ID}"
else
    SPA_CLIENT_ID=$(az ad app create \
        --display-name "${SPA_APP_NAME}" \
        --sign-in-audience "AzureADMyOrg" \
        --query appId -o tsv)
    echo -e "  ${GREEN}✅ Created:${NC} ${SPA_CLIENT_ID}"
fi

SPA_OBJECT_ID=$(az ad app show --id "${SPA_CLIENT_ID}" --query id -o tsv)

# Configure SPA redirect URIs
REDIRECT_URIS='["http://localhost:3000","http://localhost:5173"'
if [[ -n "${FRONTEND_FQDN}" ]]; then
    REDIRECT_URIS+=",\"https://${FRONTEND_FQDN}\""
fi
REDIRECT_URIS+=']'

az rest --method PATCH \
    --uri "https://graph.microsoft.com/v1.0/applications/${SPA_OBJECT_ID}" \
    --headers 'Content-Type=application/json' \
    --body "{
        \"spa\": {
            \"redirectUris\": ${REDIRECT_URIS}
        }
    }" --output none
echo -e "  ${GREEN}✅${NC} Redirect URIs configured"

# Grant the SPA permission to the API scope
API_SP_ID=$(az ad sp show --id "${API_CLIENT_ID}" --query id -o tsv 2>/dev/null || echo "")

az rest --method PATCH \
    --uri "https://graph.microsoft.com/v1.0/applications/${SPA_OBJECT_ID}" \
    --headers 'Content-Type=application/json' \
    --body "{
        \"requiredResourceAccess\": [
            {
                \"resourceAppId\": \"${API_CLIENT_ID}\",
                \"resourceAccess\": [
                    {
                        \"id\": \"${SCOPE_ID}\",
                        \"type\": \"Scope\"
                    }
                ]
            }
        ]
    }" --output none
echo -e "  ${GREEN}✅${NC} API permission granted (Query.Execute)"

# ── Step 5: Assign current user the Admin role ─────────────
echo ""
echo -e "${BLUE}[5/6] Assigning current user the Admin app role...${NC}"

CURRENT_USER_OID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")
if [[ -n "${CURRENT_USER_OID}" && -n "${API_SP_ID}" ]]; then
    ADMIN_ROLE_ID=$(az ad app show --id "${API_CLIENT_ID}" \
        --query "appRoles[?value=='Admin'].id | [0]" -o tsv 2>/dev/null || echo "")

    if [[ -n "${ADMIN_ROLE_ID}" ]]; then
        az rest --method POST \
            --uri "https://graph.microsoft.com/v1.0/servicePrincipals/${API_SP_ID}/appRoleAssignments" \
            --headers 'Content-Type=application/json' \
            --body "{
                \"principalId\": \"${CURRENT_USER_OID}\",
                \"resourceId\": \"${API_SP_ID}\",
                \"appRoleId\": \"${ADMIN_ROLE_ID}\"
            }" --output none 2>/dev/null \
            && echo -e "  ${GREEN}✅${NC} Admin role assigned to current user" \
            || echo -e "  ${YELLOW}⚠  Role may already be assigned${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠  Could not determine current user or SP — assign roles manually in Azure Portal${NC}"
fi

# ── Step 6: Update Container Apps env vars ─────────────────
echo ""
echo -e "${BLUE}[6/6] Updating Container Apps environment variables...${NC}"

AUTHORITY="https://login.microsoftonline.com/${TENANT_ID}"
API_SCOPE="${API_ID_URI}/Query.Execute"

# Update backend
echo -e "  Updating backend (${RESOURCE_PREFIX}-api)..."
az containerapp update \
    --name "${RESOURCE_PREFIX}-api" \
    --resource-group "${RESOURCE_GROUP}" \
    --set-env-vars \
        "AZURE_TENANT_ID=${TENANT_ID}" \
        "AZURE_CLIENT_ID=${API_CLIENT_ID}" \
    --output none 2>/dev/null \
    && echo -e "  ${GREEN}✔${NC} Backend env vars updated" \
    || echo -e "  ${YELLOW}⚠  Backend update failed${NC}"

# Update frontend (build-time vars are baked in, but we can set them for reference)
echo -e "  Updating frontend (${RESOURCE_PREFIX}-frontend)..."
az containerapp update \
    --name "${RESOURCE_PREFIX}-frontend" \
    --resource-group "${RESOURCE_GROUP}" \
    --set-env-vars \
        "VITE_AZURE_CLIENT_ID=${SPA_CLIENT_ID}" \
        "VITE_AZURE_TENANT_ID=${TENANT_ID}" \
        "VITE_AZURE_AUTHORITY=${AUTHORITY}" \
        "VITE_API_SCOPE=${API_SCOPE}" \
        "VITE_API_BASE_URL=https://${BACKEND_FQDN}" \
    --output none 2>/dev/null \
    && echo -e "  ${GREEN}✔${NC} Frontend env vars updated" \
    || echo -e "  ${YELLOW}⚠  Frontend update failed${NC}"

# ── Summary ────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${BLUE}══════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN} Entra ID Setup Complete${NC}"
echo -e "${BOLD}${BLUE}══════════════════════════════════════════════${NC}"
echo -e " API App Registration:"
echo -e "   Name:      ${BOLD}${API_APP_NAME}${NC}"
echo -e "   Client ID: ${BOLD}${API_CLIENT_ID}${NC}"
echo -e "   URI:       ${BOLD}${API_ID_URI}${NC}"
echo -e "   Scope:     ${BOLD}${API_ID_URI}/Query.Execute${NC}"
echo -e "   Roles:     Tenant.Acme, Tenant.Nova, Tenant.Apex, Admin"
echo ""
echo -e " SPA App Registration:"
echo -e "   Name:      ${BOLD}${SPA_APP_NAME}${NC}"
echo -e "   Client ID: ${BOLD}${SPA_CLIENT_ID}${NC}"
echo -e "   Redirects: localhost:3000, localhost:5173${FRONTEND_FQDN:+, https://${FRONTEND_FQDN}}"
echo ""
echo -e " ${YELLOW}Important:${NC}"
echo -e "   • The frontend uses build-time env vars (VITE_*). To use the new"
echo -e "     client IDs in the deployed frontend, rebuild the Docker image"
echo -e "     with the correct .env values and push again."
echo -e "   • For local dev, update ${BOLD}frontend/.env${NC}:"
echo -e "     VITE_AZURE_CLIENT_ID=${SPA_CLIENT_ID}"
echo -e "     VITE_AZURE_TENANT_ID=${TENANT_ID}"
echo -e "     VITE_AZURE_AUTHORITY=${AUTHORITY}"
echo -e "     VITE_API_SCOPE=${API_SCOPE}"
echo -e "   • For local dev, update ${BOLD}backend/.env${NC}:"
echo -e "     AZURE_TENANT_ID=${TENANT_ID}"
echo -e "     AZURE_CLIENT_ID=${API_CLIENT_ID}"
echo -e "${BOLD}${BLUE}══════════════════════════════════════════════${NC}"
