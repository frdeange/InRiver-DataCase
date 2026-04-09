#!/bin/bash
# Deploy InRiver DataCase infrastructure to RG-InRiver
# Usage: ./infra/deploy.sh [--what-if]
#
# Prerequisites:
#   - az login && az account set --subscription <id>
#   - Copy infra/parameters.demo.json.example → infra/parameters.demo.json and fill in secrets

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCE_GROUP="RG-InRiver"
TEMPLATE="${SCRIPT_DIR}/main.bicep"
PARAMETERS="${SCRIPT_DIR}/parameters.demo.json"

if [[ ! -f "${PARAMETERS}" ]]; then
  echo "ERROR: ${PARAMETERS} not found."
  echo "Copy ${PARAMETERS}.example → ${PARAMETERS} and fill in the secret values."
  exit 1
fi

# Pass --what-if flag to preview changes without deploying
WHAT_IF_FLAG=""
if [[ "${1:-}" == "--what-if" ]]; then
  WHAT_IF_FLAG="--what-if"
  echo "Running in what-if (preview) mode..."
fi

echo "Deploying InRiver DataCase to resource group: ${RESOURCE_GROUP}"
echo "Template : ${TEMPLATE}"
echo "Parameters: ${PARAMETERS}"
echo ""

az deployment group create \
  --resource-group "${RESOURCE_GROUP}" \
  --template-file "${TEMPLATE}" \
  --parameters "@${PARAMETERS}" \
  --name "inriver-datacase-$(date +%Y%m%d%H%M%S)" \
  ${WHAT_IF_FLAG} \
  --output table

echo ""
echo "Deployment complete. Run the database init scripts to set up the PIM schema:"
echo "  See database/ directory for SQL scripts."
