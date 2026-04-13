"""InRiver DataCase MCP Tools Server.

Exposes get_schema, validate_sql, execute_sql as MCP tools
for consumption by AI agents via Streamable HTTP.
"""

import json
import logging
import struct
from pathlib import Path

import structlog
import sqlglot
from fastmcp import FastMCP
from sqlglot.errors import ParseError

logger = structlog.get_logger()

mcp = FastMCP(
    name="InRiver SQL Tools",
    instructions="Tools for querying InRiver PIM databases. Use get_schema first, then validate and execute SQL.",
)

# ─── Schema Provider ───────────────────────────────────────

_SCHEMA_PATHS = [
    Path("/app/schema.sql"),
    Path(__file__).resolve().parent.parent / "schema.sql",
    Path("/workspaces/InRiver-DataCase/database/schema.sql"),
]


@mcp.tool()
def get_schema(database: str) -> str:
    """Return the PIM database schema (CREATE TABLE statements).

    The schema is identical across all tenant databases.
    Use this to understand available tables, columns, and relationships
    before generating SQL queries.
    """
    for path in _SCHEMA_PATHS:
        if path.is_file():
            return path.read_text(encoding="utf-8")
    return (
        "-- InRiver PIM Schema (summary)\n"
        "-- Tables: Categories(CategoryId, CategoryName, ParentCategoryId, Description, IsActive)\n"
        "-- Products(ProductId, ProductNumber, ProductName, Description, CategoryId, Brand, Status, ListPrice, Currency, SKU, IsActive)\n"
        "-- Attributes(AttributeId, AttributeName, DataType, Unit, IsRequired)\n"
        "-- ProductAttributes(ProductAttributeId, ProductId, AttributeId, Value)\n"
        "-- Customers(CustomerId, CustomerName, ContactEmail, Country, Segment, IsActive)\n"
        "-- Orders(OrderId, OrderNumber, CustomerId, ProductId, Quantity, UnitPrice, TotalAmount, OrderDate, Status)\n"
    )


# ─── SQL Validator ─────────────────────────────────────────

FORBIDDEN_TYPES = {
    "INSERT",
    "UPDATE",
    "DELETE",
    "DROP",
    "ALTER",
    "EXEC",
    "TRUNCATE",
    "CREATE",
    "MERGE",
    "GRANT",
    "REVOKE",
}


@mcp.tool()
def validate_sql(sql: str) -> str:
    """Validate that a SQL query is a safe SELECT-only statement.

    Uses AST-level parsing with sqlglot. Returns JSON:
    {"valid": true/false, "reason": "explanation"}
    """
    if not sql or not sql.strip():
        return json.dumps({"valid": False, "reason": "Empty SQL statement"})

    try:
        parsed = sqlglot.parse(sql, dialect="tsql")
    except ParseError as exc:
        return json.dumps({"valid": False, "reason": f"Parse error: {exc}"})

    if not parsed:
        return json.dumps({"valid": False, "reason": "No statements parsed"})

    for statement in parsed:
        if statement is None:
            continue
        stmt_type = statement.key.upper()
        if stmt_type in FORBIDDEN_TYPES:
            return json.dumps(
                {"valid": False, "reason": f"Forbidden statement type: {stmt_type}"}
            )
        if stmt_type != "SELECT":
            upper_sql = sql.strip().upper()
            for kw in FORBIDDEN_TYPES:
                if upper_sql.startswith(kw):
                    return json.dumps(
                        {"valid": False, "reason": f"Forbidden statement type: {kw}"}
                    )

    return json.dumps({"valid": True, "reason": "Valid SELECT statement"})


# ─── SQL Executor ──────────────────────────────────────────


def _get_azure_sql_token() -> bytes:
    """Get Azure AD access token for Azure SQL."""
    from azure.identity import DefaultAzureCredential

    credential = DefaultAzureCredential()
    token = credential.get_token("https://database.windows.net/.default")
    token_bytes = token.token.encode("utf-16-le")
    return struct.pack(f"<I{len(token_bytes)}s", len(token_bytes), token_bytes)


@mcp.tool()
def execute_sql(sql: str, database: str) -> str:
    """Execute a validated SQL SELECT query against a tenant database.

    Connects to Azure SQL using managed identity authentication.
    Returns JSON with columns and rows:
    {"columns": ["col1", "col2"], "rows": [[val1, val2], ...], "database": "db-name"}
    """
    import os
    import pyodbc

    server = os.environ.get("SQL_SERVER", "inriver-dev-sql.database.windows.net")
    conn_str = (
        f"DRIVER={{ODBC Driver 18 for SQL Server}};"
        f"SERVER={server};"
        f"DATABASE={database};"
    )

    try:
        token_struct = _get_azure_sql_token()
        SQL_COPT_SS_ACCESS_TOKEN = 1256
        conn = pyodbc.connect(
            conn_str, attrs_before={SQL_COPT_SS_ACCESS_TOKEN: token_struct}
        )

        cursor = conn.cursor()
        cursor.execute(sql)
        columns = [desc[0] for desc in cursor.description] if cursor.description else []
        rows = [list(row) for row in cursor.fetchall()]
        cursor.close()
        conn.close()

        clean_rows = []
        for row in rows:
            clean_rows.append(
                [
                    (
                        val
                        if isinstance(val, (int, float, str, bool, type(None)))
                        else str(val)
                    )
                    for val in row
                ]
            )

        return json.dumps(
            {"columns": columns, "rows": clean_rows, "database": database}
        )

    except Exception as exc:
        logger.error("SQL execution failed: %s", exc)
        return json.dumps(
            {"columns": ["error"], "rows": [[str(exc)]], "database": database}
        )
