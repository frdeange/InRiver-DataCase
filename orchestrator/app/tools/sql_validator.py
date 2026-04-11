"""SQL validation tool using sqlglot AST parsing."""

from __future__ import annotations

import json

import sqlglot
from agent_framework import tool
from sqlglot.errors import ParseError


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


@tool(description="Validate that a SQL query is a safe SELECT-only statement. Returns JSON with valid (bool) and reason.")
def validate_sql(sql: str) -> str:
    """Validate that *sql* is a safe SELECT-only statement.

    Returns a JSON string: ``{"valid": true/false, "reason": "..."}``.
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
            # Also reject anything that is not an explicit SELECT
            upper_sql = sql.strip().upper()
            for kw in FORBIDDEN_TYPES:
                if upper_sql.startswith(kw):
                    return json.dumps(
                        {"valid": False, "reason": f"Forbidden statement type: {kw}"}
                    )

    return json.dumps({"valid": True, "reason": "Valid SELECT statement"})
