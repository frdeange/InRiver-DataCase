#!/usr/bin/env bash
# ============================================================
# InRiver-DataCase: Grant Managed Identity access to SQL DBs
# Creates a contained database user for the managed identity
# and grants db_datareader + denies write operations.
#
# Usage: ./scripts/grant-sql-access.sh <SQL_SERVER_FQDN> <IDENTITY_NAME>
# Example: ./scripts/grant-sql-access.sh inriver-dev-sql.database.windows.net inriver-dev-identity
# ============================================================
set -euo pipefail

SQL_SERVER="${1:?Usage: grant-sql-access.sh <SQL_SERVER_FQDN> <IDENTITY_NAME>}"
IDENTITY_NAME="${2:?Usage: grant-sql-access.sh <SQL_SERVER_FQDN> <IDENTITY_NAME>}"

SQLCMD="/usr/local/bin/sqlcmd"
if [[ ! -x "${SQLCMD}" ]]; then
    SQLCMD="sqlcmd"
fi

DATABASES=("db-acme" "db-nova" "db-apex")

echo "Granting SQL access to managed identity: ${IDENTITY_NAME}"
echo "SQL Server: ${SQL_SERVER}"
echo ""

for DB in "${DATABASES[@]}"; do
    echo "=== ${DB} ==="
    "${SQLCMD}" \
        -S "tcp:${SQL_SERVER},1433" \
        -d "${DB}" \
        --authentication-method=ActiveDirectoryDefault \
        -Q "
        -- Create contained database user for the managed identity
        IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '${IDENTITY_NAME}')
        BEGIN
            CREATE USER [${IDENTITY_NAME}] FROM EXTERNAL PROVIDER;
            PRINT '  User created: ${IDENTITY_NAME}';
        END
        ELSE
            PRINT '  User already exists: ${IDENTITY_NAME}';

        -- Grant read-only access
        ALTER ROLE db_datareader ADD MEMBER [${IDENTITY_NAME}];
        PRINT '  Granted db_datareader';

        -- Deny write operations (defense in depth)
        DENY INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO [${IDENTITY_NAME}];
        PRINT '  Write operations denied';
        "
    echo ""
done

echo "All databases configured."
