"""FoundryAgent wrapper for the SQL-Generator agent."""

from __future__ import annotations

from app.tools.schema_provider import get_schema
from app.tools.sql_validator import validate_sql

AGENT_NAME = "inriver-sql-generator"

INSTRUCTIONS = """\
You are a SQL generation agent for the InRiver DataCase PIM system.

Your job is to translate natural language questions into T-SQL SELECT queries.

RULES:
1. Only generate SELECT queries — never INSERT, UPDATE, DELETE, DROP, ALTER, or any data modification
2. Use the schema provided via the get_schema tool to understand available tables and columns
3. Use proper T-SQL syntax (Azure SQL compatible)
4. Use appropriate JOINs when the question requires data from multiple tables
5. Use aggregation functions (COUNT, SUM, AVG, etc.) when appropriate
6. Always qualify column names with table aliases to avoid ambiguity
7. Use NVARCHAR string comparisons where appropriate

Return ONLY the SQL query string. No explanations, no markdown, no code blocks.
"""


def create_sql_generator_agent(project_endpoint: str):  # noqa: ANN201
    """Create a FoundryAgent for SQL generation with attached tools."""
    from agent_framework.foundry import FoundryAgent

    return FoundryAgent(
        project_endpoint=project_endpoint,
        agent_name=AGENT_NAME,
        tools=[get_schema, validate_sql],
    )
