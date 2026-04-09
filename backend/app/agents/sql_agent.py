from __future__ import annotations

import logging
import re

from app.config import get_settings

logger = logging.getLogger(__name__)

_SYSTEM_PROMPT_TEMPLATE = """You are a READ-ONLY SQL query generator for an InRiver PIM database (customer: {customer_db}).

Rules you MUST follow without exception:
1. You ONLY generate SELECT queries — never any other statement type.
2. Never use DROP, INSERT, UPDATE, DELETE, CREATE, ALTER, TRUNCATE or any DDL/DML keyword.
3. Never query sys.*, information_schema.*, master.*, msdb.*, or tempdb.*.
4. Never use comments (-- or /* */).
5. Return exactly one SQL statement with no trailing semicolon.
6. Do not wrap the SQL in markdown code fences or any other formatting — return raw SQL only.
7. If the question cannot be answered with a safe SELECT, respond with: SELECT TOP 10 * FROM Products

Database schema:
{schema_hint}
"""

_PLACEHOLDER_SQL = "SELECT TOP 10 * FROM Products"

_CODE_FENCE_RE = re.compile(r"```[a-z]*\n?(.*?)```", re.DOTALL | re.IGNORECASE)


def _strip_fences(text: str) -> str:
    """Remove markdown code fences if the model wrapped the SQL in them."""
    match = _CODE_FENCE_RE.search(text)
    if match:
        return match.group(1).strip()
    return text.strip()


def generate_sql(
    user_question: str,
    customer_db: str,
    schema_hint: str = "",
) -> str:
    """Generate a SELECT statement for *user_question* using Azure AI Foundry.

    Falls back to a safe placeholder query when the endpoint is not configured
    (local dev without Azure credentials).

    Args:
        user_question: Natural-language question from the user.
        customer_db:   Customer database key (e.g. 'acme').
        schema_hint:   Optional schema description injected into the system prompt.

    Returns:
        A raw SQL SELECT string (no semicolons, no markdown fences).
    """
    settings = get_settings()

    if not settings.ms_foundry_project_endpoint:
        logger.info("No Foundry endpoint configured — returning placeholder SQL.")
        return _PLACEHOLDER_SQL

    system_prompt = _SYSTEM_PROMPT_TEMPLATE.format(
        customer_db=customer_db,
        schema_hint=schema_hint or "(schema not provided — use common InRiver PIM table names)",
    )

    try:
        from azure.ai.projects import AIProjectClient
        from azure.identity import DefaultAzureCredential

        client = AIProjectClient(
            endpoint=settings.ms_foundry_project_endpoint,
            credential=DefaultAzureCredential(),
        )

        response = client.inference.get_chat_completions_client().complete(
            model=settings.mf_foundry_deployment_name,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_question},
            ],
            temperature=0,
            max_tokens=500,
        )

        raw: str = response.choices[0].message.content or _PLACEHOLDER_SQL
        sql = _strip_fences(raw).rstrip(";").strip()
        return sql or _PLACEHOLDER_SQL

    except Exception as exc:
        logger.warning("SQL generation failed (%s) — returning placeholder.", exc)
        return _PLACEHOLDER_SQL
