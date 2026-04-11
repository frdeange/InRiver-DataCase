import asyncio
import struct
import time
import structlog
from app.config import settings

logger = structlog.get_logger(__name__)

QUERY_TIMEOUT_SECONDS = 15
MAX_ROWS = 500


def _get_token_bytes() -> bytes:
    """Get an Azure AD access token for SQL and pack it into the ODBC connect attrs format."""
    from app.auth.azure_credential import get_azure_credential

    credential = get_azure_credential()
    token = credential.get_token("https://database.windows.net/.default")
    # Pack the token string as required by ODBC SQL_COPT_SS_ACCESS_TOKEN
    token_bytes = token.token.encode("utf-16-le")
    return struct.pack(f"<I{len(token_bytes)}s", len(token_bytes), token_bytes)


def _clean_conn_str(conn_str: str) -> str:
    """Remove Authentication= from connection string (we use token auth instead)."""
    parts = [
        p
        for p in conn_str.split(";")
        if not p.strip().lower().startswith("authentication=")
    ]
    return ";".join(parts)


async def execute_validated_query(sql: str, tenant_db: str, request_id: str) -> dict:
    """Execute validated SQL against the tenant-scoped database.
    This is the ONLY function in the codebase that executes SQL.

    Uses Azure AD token authentication via DefaultAzureCredential.
    In local dev: picks up your az login session.
    In Container Apps: uses the managed identity.
    """
    conn_str = settings.tenant_connections.get(tenant_db)
    if not conn_str:
        raise ValueError(f"No connection configured for tenant: {tenant_db}")

    start = time.monotonic()

    try:
        import aioodbc

        # Remove Authentication= and use token-based auth instead
        clean_str = _clean_conn_str(conn_str)
        token_bytes = _get_token_bytes()
        # SQL_COPT_SS_ACCESS_TOKEN = 1256
        async with aioodbc.connect(
            dsn=clean_str,
            timeout=QUERY_TIMEOUT_SECONDS,
            attrs_before={1256: token_bytes},
        ) as conn:
            async with conn.cursor() as cursor:
                await cursor.execute("SET ROWCOUNT 500")
                await cursor.execute(sql)

                columns = (
                    [desc[0] for desc in cursor.description]
                    if cursor.description
                    else []
                )
                rows = []
                async for row in cursor:
                    rows.append(list(row))
                    if len(rows) >= MAX_ROWS:
                        break

                duration_ms = int((time.monotonic() - start) * 1000)
                return {
                    "columns": columns,
                    "rows": rows,
                    "row_count": len(rows),
                    "execution_time_ms": duration_ms,
                    "truncated": len(rows) >= MAX_ROWS,
                }
    except asyncio.TimeoutError:
        raise TimeoutError(f"Query timed out after {QUERY_TIMEOUT_SECONDS}s")
    except ImportError:
        # Fallback for local dev without ODBC driver — return mock data
        logger.warning(
            "aioodbc_not_available", msg="Using mock data for local development"
        )
        return _mock_execute(sql, tenant_db)


def _mock_execute(sql: str, tenant_db: str) -> dict:
    """Mock execution for local development without Azure SQL."""
    # Parse a simple query to return plausible mock data
    return {
        "columns": ["ProductId", "ProductName", "ListPrice"],
        "rows": [
            [1, f"Mock Product 1 ({tenant_db})", 29.99],
            [2, f"Mock Product 2 ({tenant_db})", 49.99],
            [3, f"Mock Product 3 ({tenant_db})", 99.99],
        ],
        "row_count": 3,
        "execution_time_ms": 10,
        "truncated": False,
    }
