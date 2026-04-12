"""FoundryAgent wrapper for the SQL-Generator agent."""

from __future__ import annotations

from app.tools.schema_provider import get_schema
from app.tools.sql_executor import execute_sql
from app.tools.sql_validator import validate_sql

AGENT_NAME = "inriver-sql-generator"

INSTRUCTIONS = """\
You are a SQL generation agent for the InRiver DataCase PIM system.

Your workflow:
1. Call the get_schema tool to understand available tables and columns
2. Generate a T-SQL SELECT query based on the user's question
3. Call the validate_sql tool to verify the query is safe
4. If valid, call the execute_sql tool to run it against the database
5. After getting results, hand off to inriver-response-formatter by calling transfer_to_inriver-response-formatter with the original question, the SQL you generated, and the query results

RULES:
- Only generate SELECT queries — never INSERT, UPDATE, DELETE, DROP, ALTER, or any data modification
- Use proper T-SQL syntax (Azure SQL compatible)
- Use appropriate JOINs when the question requires data from multiple tables
- Use aggregation functions (COUNT, SUM, AVG, etc.) when appropriate
- Always qualify column names with table aliases to avoid ambiguity
- The database name is provided in the user's message — use it with the tools
"""


def create_sql_generator_agent(project_endpoint: str):  # noqa: ANN201
    """Create a FoundryAgent for SQL generation with attached tools."""
    from azure.identity import DefaultAzureCredential
    from agent_framework.foundry import FoundryAgent

    return FoundryAgent(
        project_endpoint=project_endpoint,
        agent_name=AGENT_NAME,
        credential=DefaultAzureCredential(),
        tools=[get_schema, validate_sql, execute_sql],
    )
