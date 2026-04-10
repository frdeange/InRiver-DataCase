#!/usr/bin/env bash
# ============================================================
# InRiver-DataCase: Database Schema + Seed Script
# Runs schema.sql then tenant-specific seed against each DB
# Usage: ./scripts/seed-databases.sh <SQL_SERVER_FQDN>
# ============================================================
set -euo pipefail

SQL_SERVER="${1:?Usage: seed-databases.sh <SQL_SERVER_FQDN>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_DIR="${SCRIPT_DIR}/../database"

# Tenant databases and their seed files
declare -A TENANT_SEEDS=(
    ["db-acme"]="seed-acme.sql"
    ["db-nova"]="seed-nova.sql"
    ["db-apex"]="seed-apex.sql"
)

# Use Azure AD authentication via az cli token
echo "Acquiring Azure AD access token for SQL..."
ACCESS_TOKEN=$(az account get-access-token \
    --resource https://database.windows.net/ \
    --query accessToken -o tsv)

for DB_NAME in "${!TENANT_SEEDS[@]}"; do
    SEED_FILE="${TENANT_SEEDS[$DB_NAME]}"

    echo ""
    echo "=========================================="
    echo " Database: ${DB_NAME}"
    echo "=========================================="

    # Apply schema
    echo "  Applying schema.sql..."
    sqlcmd \
        -S "tcp:${SQL_SERVER},1433" \
        -d "${DB_NAME}" \
        -G -P "${ACCESS_TOKEN}" \
        -i "${DB_DIR}/schema.sql" \
        -b

    # Apply seed data
    echo "  Applying ${SEED_FILE}..."
    sqlcmd \
        -S "tcp:${SQL_SERVER},1433" \
        -d "${DB_NAME}" \
        -G -P "${ACCESS_TOKEN}" \
        -i "${DB_DIR}/${SEED_FILE}" \
        -b

    echo "  Done: ${DB_NAME}"
done

echo ""
echo "All databases seeded successfully."
