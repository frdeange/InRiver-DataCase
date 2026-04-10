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

# Use the Go-based sqlcmd with Azure AD authentication.
# Requires: go-sqlcmd (install via: curl from github.com/microsoft/go-sqlcmd)
# Falls back to /usr/local/bin/sqlcmd if mssql-tools18 sqlcmd is first in PATH.
SQLCMD="/usr/local/bin/sqlcmd"
if [[ ! -x "${SQLCMD}" ]]; then
    SQLCMD="sqlcmd"
fi
echo "Using sqlcmd: $(${SQLCMD} --version 2>/dev/null | head -1 || echo 'unknown')"

for DB_NAME in "${!TENANT_SEEDS[@]}"; do
    SEED_FILE="${TENANT_SEEDS[$DB_NAME]}"

    echo ""
    echo "=========================================="
    echo " Database: ${DB_NAME}"
    echo "=========================================="

    # Apply schema
    echo "  Applying schema.sql..."
    "${SQLCMD}" \
        -S "tcp:${SQL_SERVER},1433" \
        -d "${DB_NAME}" \
        --authentication-method=ActiveDirectoryDefault \
        -i "${DB_DIR}/schema.sql"

    # Apply seed data
    echo "  Applying ${SEED_FILE}..."
    "${SQLCMD}" \
        -S "tcp:${SQL_SERVER},1433" \
        -d "${DB_NAME}" \
        --authentication-method=ActiveDirectoryDefault \
        -i "${DB_DIR}/${SEED_FILE}"

    echo "  Done: ${DB_NAME}"
done

echo ""
echo "All databases seeded successfully."
