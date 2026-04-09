from __future__ import annotations

import json
import logging
from typing import Any

from openai import AzureOpenAI

from app.config import get_settings
from app.agents.schema_context import build_schema_string

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# OpenAI function-calling tool definition
# ---------------------------------------------------------------------------
_TOOLS: list[dict[str, Any]] = [
    {
        "type": "function",
        "function": {
            "name": "execute_sql_query",
            "description": "Execute a SQL SELECT query against the PIM database",
            "parameters": {
                "type": "object",
                "properties": {
                    "sql_query": {
                        "type": "string",
                        "description": "The SQL SELECT query to execute",
                    },
                    "explanation": {
                        "type": "string",
                        "description": "Plain English explanation of what this query does",
                    },
                },
                "required": ["sql_query", "explanation"],
            },
        },
    }
]

# ---------------------------------------------------------------------------
# System prompt
# ---------------------------------------------------------------------------
_SYSTEM_PROMPT_TEMPLATE = """\
You are a SQL query assistant for a Product Information Management (PIM) database.
Your ONLY job is to translate natural language questions into valid T-SQL SELECT queries.

Rules:
- Generate ONLY SELECT queries. Never generate INSERT, UPDATE, DELETE, DROP, CREATE, ALTER, EXEC, \
EXECUTE, TRUNCATE, MERGE, GRANT, REVOKE, or any other non-SELECT statement.
- Never access system tables (sys.*, information_schema.* unless explicitly for schema lookup).
- Use only tables and columns that exist in the provided schema.
- Always use table aliases for clarity.
- Limit results to 100 rows maximum using TOP 100 unless the user specifies a smaller limit.
- If you cannot answer the question with the available schema, say so — do not hallucinate \
tables or columns.
- Always call the execute_sql_query function with your result.

Database schema:
{schema_context}
"""


def _get_system_prompt() -> str:
    return _SYSTEM_PROMPT_TEMPLATE.format(schema_context=build_schema_string())


def _get_client() -> AzureOpenAI:
    settings = get_settings()
    return AzureOpenAI(
        azure_endpoint=settings.azure_openai_endpoint,
        api_key=settings.azure_openai_key,
        api_version="2024-02-15-preview",
    )


def _parse_tool_call(response_message: Any) -> tuple[str, str] | None:
    """Extract (sql_query, explanation) from a tool-call response, or None."""
    tool_calls = getattr(response_message, "tool_calls", None)
    if not tool_calls:
        return None
    for tc in tool_calls:
        if tc.function.name == "execute_sql_query":
            try:
                args = json.loads(tc.function.arguments)
                return args["sql_query"], args["explanation"]
            except (json.JSONDecodeError, KeyError) as exc:
                logger.warning("Failed to parse tool call arguments: %s", exc)
    return None


def generate_sql(
    question: str,
    *,
    error_feedback: str | None = None,
    previous_sql: str | None = None,
) -> tuple[str, str]:
    """Call Azure OpenAI to generate a T-SQL SELECT query for *question*.

    Args:
        question: Natural-language question from the user.
        error_feedback: If retrying after a failure, the error message to feed back.
        previous_sql: The SQL that failed (included in error feedback message).

    Returns:
        Tuple of (sql_query, explanation).

    Raises:
        RuntimeError: If the model does not return a valid tool call.
    """
    settings = get_settings()
    client = _get_client()

    messages: list[dict[str, Any]] = [
        {"role": "system", "content": _get_system_prompt()},
    ]

    if error_feedback and previous_sql:
        messages.append({"role": "user", "content": question})
        messages.append({"role": "assistant", "content": f"Generated SQL:\n{previous_sql}"})
        messages.append({
            "role": "user",
            "content": f"The previous query failed with error: {error_feedback}. Please correct it and try again.",
        })
    else:
        messages.append({"role": "user", "content": question})

    response = client.chat.completions.create(
        model=settings.azure_openai_deployment,
        messages=messages,
        tools=_TOOLS,
        tool_choice={"type": "function", "function": {"name": "execute_sql_query"}},
        temperature=0,
    )

    result = _parse_tool_call(response.choices[0].message)
    if result is None:
        raise RuntimeError("AI agent did not return a valid SQL tool call.")
    return result


def run_sql_agent(
    question: str,
    customer_db: str,
    *,
    sql_validator: Any | None = None,
    db_executor: Any | None = None,
) -> dict[str, Any]:
    """Orchestrate the full AI → validate → execute loop.

    Args:
        question: User's natural-language question.
        customer_db: Database key ('acme', 'nova', 'apex').
        sql_validator: Callable(sql) → None | raises ValueError with reason.
        db_executor: Callable(customer_db, sql) → list[dict]. Defaults to connections.execute_query.

    Returns:
        Dict with keys: sql, explanation, results, row_count.

    Raises:
        ValueError: If guardrails reject the query (after 1 retry).
        RuntimeError: If execution fails (after 1 retry).
    """
    from app.db.connections import execute_query as _default_executor

    executor = db_executor or _default_executor

    # First attempt
    sql, explanation = generate_sql(question)
    error: str | None = None

    for attempt in range(2):
        # --- Guardrail validation ---
        if sql_validator is not None:
            try:
                sql_validator(sql)
            except Exception as val_err:
                error = str(val_err)
                if attempt == 0:
                    logger.info("SQL guardrail rejected query (attempt 1), retrying: %s", error)
                    sql, explanation = generate_sql(question, error_feedback=error, previous_sql=sql)
                    continue
                else:
                    raise ValueError(f"SQL rejected by guardrails: {error}") from val_err

        # --- DB execution ---
        try:
            results = executor(customer_db, sql)
            return {
                "sql": sql,
                "explanation": explanation,
                "results": results,
                "row_count": len(results),
            }
        except Exception as db_err:
            error = str(db_err)
            if attempt == 0:
                logger.info("DB execution failed (attempt 1), retrying: %s", error)
                sql, explanation = generate_sql(question, error_feedback=error, previous_sql=sql)
                continue
            else:
                raise RuntimeError(f"Query execution failed: {error}") from db_err

    # Should not reach here, but just in case
    raise RuntimeError("SQL agent exhausted retries without a result.")
