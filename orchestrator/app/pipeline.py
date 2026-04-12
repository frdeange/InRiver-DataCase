"""Orchestration pipeline — mock and real implementations."""

from __future__ import annotations

import json
import re
import time
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any

from app.config import settings
from app.tools.schema_provider import get_schema
from app.tools.sql_executor import execute_sql
from app.tools.sql_validator import validate_sql


@dataclass
class PipelineResult:
    """Result returned by the pipeline."""

    answer: str
    sql: str
    database: str
    execution_time_ms: float
    columns: list[str] | None = None
    rows: list[list] | None = None
    safe: bool = True
    error: str | None = None


class BasePipeline(ABC):
    """Abstract base for pipeline implementations."""

    @abstractmethod
    async def run(
        self, question: str, database: str, schema: str, user_email: str
    ) -> PipelineResult:
        ...


# ---------------------------------------------------------------------------
# Mock pipeline — works without Azure AI Foundry
# ---------------------------------------------------------------------------

_INJECTION_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r";\s*DROP\s", re.IGNORECASE),
    re.compile(r";\s*DELETE\s", re.IGNORECASE),
    re.compile(r"'\s*;\s*--", re.IGNORECASE),
    re.compile(r"UNION\s+SELECT\s.*FROM\s+sys\.", re.IGNORECASE),
    re.compile(r"EXEC\s*\(", re.IGNORECASE),
    re.compile(r"xp_cmdshell", re.IGNORECASE),
    re.compile(r";\s*TRUNCATE\s", re.IGNORECASE),
    re.compile(r";\s*ALTER\s", re.IGNORECASE),
    re.compile(r";\s*INSERT\s", re.IGNORECASE),
    re.compile(r";\s*UPDATE\s", re.IGNORECASE),
]

_QUERY_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (
        re.compile(r"(show|list|get)\s+(all\s+)?products", re.IGNORECASE),
        "SELECT p.ProductId, p.ProductNumber, p.ProductName, p.Status, p.ListPrice FROM Products p",
    ),
    (
        re.compile(r"count\s+(the\s+)?(products|items)", re.IGNORECASE),
        "SELECT COUNT(*) AS ProductCount FROM Products p",
    ),
    (
        re.compile(r"(show|list|get)\s+(all\s+)?orders", re.IGNORECASE),
        (
            "SELECT o.OrderId, o.OrderNumber, c.CustomerName, o.Quantity, o.TotalAmount "
            "FROM Orders o JOIN Customers c ON o.CustomerId = c.CustomerId"
        ),
    ),
    (
        re.compile(r"count\s+(the\s+)?orders", re.IGNORECASE),
        "SELECT COUNT(*) AS OrderCount FROM Orders o",
    ),
    (
        re.compile(r"(show|list|get)\s+(all\s+)?customers", re.IGNORECASE),
        "SELECT c.CustomerId, c.CustomerName, c.Country, c.Segment FROM Customers c",
    ),
    (
        re.compile(r"(show|list|get)\s+(all\s+)?categor", re.IGNORECASE),
        "SELECT cat.CategoryId, cat.CategoryName, cat.IsActive FROM Categories cat",
    ),
    (
        re.compile(r"average\s+price", re.IGNORECASE),
        "SELECT AVG(p.ListPrice) AS AvgPrice FROM Products p",
    ),
]


class MockPipeline(BasePipeline):
    """Local-dev pipeline that simulates the three-agent flow."""

    # -- safety ----------------------------------------------------------
    def _check_safety(self, question: str) -> dict[str, Any]:
        for pattern in _INJECTION_PATTERNS:
            if pattern.search(question):
                return {"safe": False, "reason": "Potential SQL injection detected"}
        return {"safe": True, "reason": "Input appears safe"}

    # -- sql generation --------------------------------------------------
    def _generate_sql(self, question: str, database: str) -> str:
        for pattern, sql_template in _QUERY_PATTERNS:
            if pattern.search(question):
                return sql_template
        # Fallback: products query
        return (
            "SELECT p.ProductId, p.ProductNumber, p.ProductName "
            "FROM Products p WHERE p.IsActive = 1"
        )

    # -- response formatting ---------------------------------------------
    @staticmethod
    def _format_response(question: str, sql: str, raw_data: str) -> str:
        data = json.loads(raw_data)
        rows = data.get("rows", [])
        columns = data.get("columns", [])

        if not rows:
            return "No results found for your query."

        if len(columns) == 1 and len(rows) == 1:
            return f"The result is {rows[0][0]}."

        row_count = len(rows)
        return (
            f"Found {row_count} result{'s' if row_count != 1 else ''}. "
            f"Columns: {', '.join(columns)}."
        )

    # -- pipeline entry --------------------------------------------------
    async def run(
        self, question: str, database: str, schema: str, user_email: str
    ) -> PipelineResult:
        start = time.perf_counter()

        # Step 1: Safety
        safety = self._check_safety(question)
        if not safety["safe"]:
            elapsed = (time.perf_counter() - start) * 1000
            return PipelineResult(
                answer=f"Query rejected: {safety['reason']}",
                sql="",
                database=database,
                execution_time_ms=elapsed,
                safe=False,
                error=safety["reason"],
            )

        # Step 2: SQL generation
        sql = self._generate_sql(question, database)

        # Step 3: Validation
        validation = json.loads(validate_sql(sql))
        if not validation["valid"]:
            elapsed = (time.perf_counter() - start) * 1000
            return PipelineResult(
                answer=f"Generated SQL failed validation: {validation['reason']}",
                sql=sql,
                database=database,
                execution_time_ms=elapsed,
                error=validation["reason"],
            )

        # Step 4: Execution
        raw_data = execute_sql(sql, database)
        parsed_data = json.loads(raw_data)

        # Step 5: Formatting
        answer = self._format_response(question, sql, raw_data)

        elapsed = (time.perf_counter() - start) * 1000
        return PipelineResult(
            answer=answer,
            sql=sql,
            database=database,
            execution_time_ms=elapsed,
            columns=parsed_data.get("columns"),
            rows=parsed_data.get("rows"),
        )


# ---------------------------------------------------------------------------
# Real pipeline — requires Azure AI Foundry
# ---------------------------------------------------------------------------


class RealPipeline(BasePipeline):
    """Production pipeline: pure FoundryAgent + SequentialBuilder.

    All agents are FoundryAgent (registered PromptAgents in Azure AI Foundry).
    MCP tools are configured ON THE AGENTS IN FOUNDRY — not in SDK code.
    Foundry handles tool calls to the MCP server automatically.
    SequentialBuilder orchestrates the conversation: Safety → SQLGenerator → Formatter.
    """

    def __init__(self) -> None:
        from agent_framework.foundry import FoundryAgent
        from agent_framework.orchestrations import SequentialBuilder
        from azure.identity import DefaultAzureCredential

        endpoint = settings.AI_PROJECT_ENDPOINT
        credential = DefaultAzureCredential()

        # Pure FoundryAgent — tools are configured in Foundry, not here
        self._safety = FoundryAgent(
            project_endpoint=endpoint,
            agent_name="inriver-safety",
            credential=credential,
        )

        self._sql_gen = FoundryAgent(
            project_endpoint=endpoint,
            agent_name="inriver-sql-generator",
            credential=credential,
            # MCP tools configured on the agent in Foundry — Foundry calls the MCP server
        )

        self._formatter = FoundryAgent(
            project_endpoint=endpoint,
            agent_name="inriver-response-formatter",
            credential=credential,
        )

        # MAF SequentialBuilder: conversation flows Safety → SQLGenerator → Formatter
        self._workflow = SequentialBuilder(
            participants=[self._safety, self._sql_gen, self._formatter],
        ).build()

    async def run(
        self, question: str, database: str, schema: str, user_email: str
    ) -> PipelineResult:
        start = time.perf_counter()

        # The conversation flows through all agents via SequentialBuilder.
        # Tools are handled by Foundry (MCP configured on the agent).
        prompt = (
            f"User question: {question}\n"
            f"Database: {database}"
        )

        try:
            result = await self._workflow.run(prompt)

            # Extract the final answer from the workflow outputs
            answer = ""
            sql = ""
            columns = None
            rows = None

            # Get outputs — last agent's (formatter) response is the answer
            outputs = result.get_outputs()
            if outputs:
                last = outputs[-1] if isinstance(outputs, list) else outputs
                if isinstance(last, list):
                    for msg in reversed(last):
                        if hasattr(msg, 'role') and msg.role == 'assistant' and hasattr(msg, 'text') and msg.text:
                            answer = msg.text
                            break
                else:
                    answer = str(last)

            # Scan conversation for SQL and structured data
            for event in result:
                event_str = str(event)

                if not sql:
                    for line in event_str.split("\n"):
                        stripped = line.strip()
                        if stripped.upper().startswith("SELECT") and "FROM" in stripped.upper():
                            sql = stripped
                            break

                if not columns and '"columns"' in event_str and '"rows"' in event_str:
                    try:
                        idx = event_str.index('{"columns"')
                        depth = 0
                        for i in range(idx, len(event_str)):
                            if event_str[i] == '{': depth += 1
                            elif event_str[i] == '}': depth -= 1
                            if depth == 0:
                                data = json.loads(event_str[idx:i + 1])
                                columns = data.get("columns")
                                rows = data.get("rows")
                                break
                    except (json.JSONDecodeError, ValueError):
                        pass

            if not answer:
                answer = "The query was processed but no formatted response was generated."

            elapsed = (time.perf_counter() - start) * 1000
            return PipelineResult(
                answer=answer, sql=sql, database=database,
                execution_time_ms=elapsed, columns=columns, rows=rows,
            )
        except Exception as exc:
            import structlog
            structlog.get_logger().error(
                "pipeline_error",
                error=str(exc),
                error_type=type(exc).__name__,
                question=question,
                database=database,
            )
            elapsed = (time.perf_counter() - start) * 1000

            # Sanitize error message — never expose internals to users
            if "content_filter" in str(exc).lower() or "content error" in str(exc).lower():
                user_message = "Your request could not be processed. Please rephrase your question."
            else:
                user_message = "An error occurred while processing your query. Please try again."

            return PipelineResult(
                answer=user_message,
                sql="", database=database,
                execution_time_ms=elapsed, error=user_message,
            )


# ---------------------------------------------------------------------------
# Factory
# ---------------------------------------------------------------------------

_pipeline: BasePipeline | None = None


def get_pipeline() -> BasePipeline:
    """Return a pipeline instance based on config.

    USE_REAL_AGENTS=false → MockPipeline (pattern-matching SQL, works without AI Foundry)
    USE_REAL_AGENTS=true  → RealPipeline (FoundryAgent + HandoffBuilder)

    Both modes respect USE_MOCK_DB for SQL execution:
    USE_MOCK_DB=false → real Azure SQL queries
    USE_MOCK_DB=true  → hardcoded sample data
    """
    global _pipeline  # noqa: PLW0603
    if _pipeline is None:
        if settings.USE_REAL_AGENTS:
            _pipeline = RealPipeline()
        else:
            _pipeline = MockPipeline()
    return _pipeline
