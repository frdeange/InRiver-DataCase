from agent_framework import Agent
from agent_framework.foundry import FoundryChatClient
from azure.identity import DefaultAzureCredential
from app.config import settings
import structlog

logger = structlog.get_logger(__name__)

SQL_GENERATOR_INSTRUCTIONS = """You are a T-SQL query generator for a PIM (Product Information Management) database.

RULES — you MUST follow ALL of these:
1. Generate ONLY a single SELECT statement in T-SQL syntax.
2. You MUST NOT generate: INSERT, UPDATE, DELETE, DROP, ALTER, TRUNCATE, EXEC, CREATE, GRANT, MERGE.
3. You MUST NOT use: INTO, OPENROWSET, OPENQUERY, xp_, sp_, dynamic SQL, USE, GO.
4. You MUST only reference tables and columns provided in the schema context below.
5. If the question cannot be answered with the given schema, respond with: CANNOT_ANSWER: <reason>
6. Always use explicit column lists — never SELECT *.
7. Use TOP 500 if no explicit row limit is given.
8. Use parameterized values with @param syntax where appropriate.
9. Do NOT include comments (-- or /* */) in the SQL.
10. Respond with ONLY the SQL query — no explanation, no markdown, no code fences.

SCHEMA:
{schema_text}
"""


async def generate_sql(
    question: str,
    schema_context: dict,
    tenant_db: str,
    feedback: list[str] | None = None,
) -> dict:
    """Generate SQL from natural language using Microsoft Agent Framework."""

    instructions = SQL_GENERATOR_INSTRUCTIONS.format(
        schema_text=schema_context["schema_text"]
    )

    if feedback:
        instructions += (
            "\n\nPREVIOUS ATTEMPT FAILED VALIDATION. Fix these issues:\n"
            + "\n".join(f"- {v}" for v in feedback)
        )

    try:
        client = FoundryChatClient(
            credential=DefaultAzureCredential(),
            project_endpoint=settings.azure_ai_project_endpoint,
            model=settings.azure_ai_model_deployment_name,
        )
        agent = Agent(
            client=client,
            name="SQLGeneratorAgent",
            instructions=instructions,
        )
        response = await agent.run(question)
        sql = response.text.strip()

        # Clean up common LLM formatting issues
        if sql.startswith("```"):
            sql = sql.split("\n", 1)[1] if "\n" in sql else sql[3:]
        if sql.endswith("```"):
            sql = sql[:-3]
        sql = sql.strip()

        if sql.startswith("CANNOT_ANSWER"):
            return {"sql": None, "explanation": sql, "confidence": 0.0}

        return {"sql": sql, "explanation": "", "confidence": 0.8}
    except Exception as e:
        logger.error("sql_generation_failed", error=str(e))
        return {"sql": None, "explanation": str(e), "confidence": 0.0}
