from agent_framework import Agent
from agent_framework.foundry import FoundryChatClient
from app.auth.azure_credential import get_azure_credential
from app.config import settings
import structlog

logger = structlog.get_logger(__name__)

FORMATTER_INSTRUCTIONS = """You are a data response formatter. Given a user's question and SQL query results, produce a clear, helpful natural language summary.

RULES:
1. Summarize the data clearly in 1-3 sentences.
2. If the result has few rows, include key values in your summary.
3. If the result has many rows, summarize the pattern (e.g., "Found 47 products...").
4. Never fabricate data not present in the results.
5. Never include raw SQL in your response.
6. Use proper formatting: numbers with units, dates readable, etc.
7. If there are no results, say so clearly and suggest rephrasing.
"""


async def format_response(question: str, exec_result: dict) -> dict:
    """Format query results into a natural language response."""

    if exec_result["row_count"] == 0:
        return {
            "answer": "No results found for your query. Try rephrasing or broadening your question.",
            "display_type": "text",
        }

    # Build a compact text representation of results for the LLM
    columns = exec_result["columns"]
    rows = exec_result["rows"]

    # Limit to first 20 rows for the formatter prompt
    sample_rows = rows[:20]
    result_text = f"Columns: {', '.join(columns)}\n"
    for row in sample_rows:
        result_text += " | ".join(str(v) for v in row) + "\n"
    if len(rows) > 20:
        result_text += f"... and {len(rows) - 20} more rows\n"
    result_text += f"\nTotal rows: {exec_result['row_count']}"

    try:
        client = FoundryChatClient(
            credential=get_azure_credential(),
            project_endpoint=settings.azure_ai_project_endpoint,
            model=settings.azure_ai_model_deployment_name,
        )
        agent = Agent(
            client=client,
            name="ResponseFormatterAgent",
            instructions=FORMATTER_INSTRUCTIONS,
        )
        prompt = f"User question: {question}\n\nQuery results:\n{result_text}"
        response = await agent.run(prompt)

        display_type = "table" if exec_result["row_count"] > 1 else "text"

        return {"answer": response.text, "display_type": display_type}
    except Exception as e:
        logger.error("response_formatting_failed", error=str(e))
        # Fallback: raw summary
        return {
            "answer": f"Found {exec_result['row_count']} result(s) for your query.",
            "display_type": "table" if exec_result["row_count"] > 1 else "text",
        }
