"""SQL execution tool — real Azure SQL and mock modes."""

from __future__ import annotations

import json
import logging
import re
import struct

from agent_framework import tool

logger = logging.getLogger(__name__)


def _get_settings():
    from app.config import settings
    return settings


def _get_azure_sql_token() -> bytes:
    """Get Azure AD access token for Azure SQL using DefaultAzureCredential."""
    from azure.identity import DefaultAzureCredential

    credential = DefaultAzureCredential()
    token = credential.get_token("https://database.windows.net/.default")
    # pyodbc needs the token as a bytes struct
    token_bytes = token.token.encode("utf-16-le")
    token_struct = struct.pack(f"<I{len(token_bytes)}s", len(token_bytes), token_bytes)
    return token_struct


def _real_execute(sql: str, database: str) -> str:
    """Execute SQL against real Azure SQL using pyodbc + Azure AD token."""
    import pyodbc

    settings = _get_settings()
    server = settings.SQL_SERVER
    conn_str = (
        f"DRIVER={{ODBC Driver 18 for SQL Server}};"
        f"SERVER={server};"
        f"DATABASE={database};"
    )

    try:
        token_struct = _get_azure_sql_token()
        SQL_COPT_SS_ACCESS_TOKEN = 1256
        conn = pyodbc.connect(conn_str, attrs_before={SQL_COPT_SS_ACCESS_TOKEN: token_struct})

        cursor = conn.cursor()
        cursor.execute(sql)
        columns = [desc[0] for desc in cursor.description] if cursor.description else []
        rows = [list(row) for row in cursor.fetchall()]
        cursor.close()
        conn.close()

        # Convert non-serializable types
        clean_rows = []
        for row in rows:
            clean_row = []
            for val in row:
                if isinstance(val, (int, float, str, bool, type(None))):
                    clean_row.append(val)
                else:
                    clean_row.append(str(val))
            clean_rows.append(clean_row)

        return json.dumps({"columns": columns, "rows": clean_rows, "database": database})

    except Exception as exc:
        logger.error("SQL execution failed: %s", exc)
        return json.dumps({"columns": ["error"], "rows": [[str(exc)]], "database": database})


@tool(description="Execute a validated SQL SELECT query against a tenant database. Returns JSON with columns and rows.")
def execute_sql(sql: str, database: str) -> str:
    """Execute validated SQL against the tenant database.

    Uses real Azure SQL in production, mock data in dev mode.
    Returns a JSON string with ``columns`` and ``rows``.
    """
    settings = _get_settings()
    if not settings.USE_MOCK_DB:
        return _real_execute(sql, database)
    return _mock_execute(sql, database)


def _mock_execute(sql: str, database: str) -> str:
    """Return realistic sample data based on query patterns."""
    upper = sql.upper()

    if re.search(r"COUNT\s*\(", upper):
        return json.dumps(
            {"columns": ["count"], "rows": [[42]], "database": database}
        )

    if "PRODUCTS" in upper and "ORDERS" not in upper:
        return json.dumps(
            {
                "columns": [
                    "ProductId",
                    "ProductNumber",
                    "ProductName",
                    "Status",
                    "ListPrice",
                ],
                "rows": [
                    [1, "PRD-001", "Widget Alpha", "Published", 29.99],
                    [2, "PRD-002", "Widget Beta", "Draft", 49.99],
                    [3, "PRD-003", "Gadget Gamma", "Approved", 99.50],
                ],
                "database": database,
            }
        )

    if "ORDERS" in upper:
        return json.dumps(
            {
                "columns": [
                    "OrderId",
                    "OrderNumber",
                    "CustomerName",
                    "Quantity",
                    "TotalAmount",
                ],
                "rows": [
                    [1, "ORD-1001", "Acme Corp", 10, 299.90],
                    [2, "ORD-1002", "Nova LLC", 5, 249.95],
                ],
                "database": database,
            }
        )

    if "CUSTOMERS" in upper:
        return json.dumps(
            {
                "columns": ["CustomerId", "CustomerName", "Country", "Segment"],
                "rows": [
                    [1, "Acme Corp", "USA", "Enterprise"],
                    [2, "Nova LLC", "Sweden", "SMB"],
                ],
                "database": database,
            }
        )

    if "CATEGORIES" in upper:
        return json.dumps(
            {
                "columns": ["CategoryId", "CategoryName", "IsActive"],
                "rows": [
                    [1, "Electronics", True],
                    [2, "Accessories", True],
                ],
                "database": database,
            }
        )

    # Fallback
    return json.dumps(
        {
            "columns": ["result"],
            "rows": [["Query executed successfully"]],
            "database": database,
        }
    )
