#!/usr/bin/env bash
# ============================================================
# InRiver-DataCase: End-to-End Deployment Script
# Usage: ./scripts/deploy.sh [dev|staging|prod]
# ============================================================
set -euo pipefail

ENV_NAME="${1:-dev}"
LOCATION="sweedencentral" # Change as needed
RESOURCE_GROUP="rg-inriver-${ENV_NAME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=========================================="
echo " InRiver-DataCase Deployment"
echo " Environment: ${ENV_NAME}"
echo " Resource Group: ${RESOURCE_GROUP}"
echo "=========================================="

# ---- Step 0: Verify Azure CLI login ----
echo "[1/6] Checking Azure CLI login..."
if ! az account show &>/dev/null; then
    echo "ERROR: Not logged in to Azure CLI. Run 'az login' first."
    exit 1
fi

SUBSCRIPTION=$(az account show --query name -o tsv)
echo "  Subscription: ${SUBSCRIPTION}"

# ---- Step 1: Create Resource Group ----
echo "[2/6] Creating resource group..."
az group create \
    --name "${RESOURCE_GROUP}" \
    --location "${LOCATION}" \
    --output none

# ---- Step 2: Deploy Bicep infrastructure ----
echo "[3/6] Deploying Bicep infrastructure..."
DEPLOY_OUTPUT=$(az deployment group create \
    --resource-group "${RESOURCE_GROUP}" \
    --template-file "${ROOT_DIR}/infra/main.bicep" \
    --parameters envName="${ENV_NAME}" \
    --parameters location="${LOCATION}" \
    --query 'properties.outputs' \
    --output json)

ACR_LOGIN_SERVER=$(echo "${DEPLOY_OUTPUT}" | jq -r '.acrLoginServer.value')
SQL_SERVER_FQDN=$(echo "${DEPLOY_OUTPUT}" | jq -r '.sqlServerFqdn.value')

echo "  ACR: ${ACR_LOGIN_SERVER}"
echo "  SQL: ${SQL_SERVER_FQDN}"

# ---- Step 3: Build and push Docker images ----
echo "[4/6] Building and pushing Docker images..."
az acr login --name "${ACR_LOGIN_SERVER%%.*}"

RESOURCE_PREFIX="inriver-${ENV_NAME}"

# Backend API
if [ -f "${ROOT_DIR}/backend/Dockerfile" ]; then
    echo "  Building backend image..."
    docker build -t "${ACR_LOGIN_SERVER}/${RESOURCE_PREFIX}-api:latest" "${ROOT_DIR}/backend"
    docker push "${ACR_LOGIN_SERVER}/${RESOURCE_PREFIX}-api:latest"
else
    echo "  SKIP: backend/Dockerfile not found"
fi

# Frontend
if [ -f "${ROOT_DIR}/frontend/Dockerfile" ]; then
    echo "  Building frontend image..."
    docker build -t "${ACR_LOGIN_SERVER}/${RESOURCE_PREFIX}-frontend:latest" "${ROOT_DIR}/frontend"
    docker push "${ACR_LOGIN_SERVER}/${RESOURCE_PREFIX}-frontend:latest"
else
    echo "  SKIP: frontend/Dockerfile not found"
fi

# ---- Step 4: Seed databases ----
echo "[5/6] Seeding databases..."
"${SCRIPT_DIR}/seed-databases.sh" "${SQL_SERVER_FQDN}"

# ---- Step 5: Summary ----
echo "[6/6] Deployment complete!"
echo ""
echo "=========================================="
echo " Deployment Summary"
echo "=========================================="
echo " ACR Login Server:  ${ACR_LOGIN_SERVER}"
echo " SQL Server FQDN:   ${SQL_SERVER_FQDN}"
echo " Frontend URL:      $(echo "${DEPLOY_OUTPUT}" | jq -r '.frontendUrl.value')"
echo " Backend URL:       $(echo "${DEPLOY_OUTPUT}" | jq -r '.backendUrl.value')"
echo " Key Vault:         $(echo "${DEPLOY_OUTPUT}" | jq -r '.keyVaultName.value')"
echo "=========================================="
