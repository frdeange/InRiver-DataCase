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
    """Production pipeline using FoundryAgent — invokes registered agents in AI Foundry.

    Each agent is a persistent PromptAgent registered in Azure AI Foundry.
    Called sequentially: Safety → SQLGenerator (with FunctionTools) → Formatter.
    All invocations produce traces visible in the Foundry portal.
    """

    def __init__(self) -> None:
        from agent_framework.foundry import FoundryAgent
        from azure.identity import DefaultAzureCredential

        from app.tools.schema_provider import get_schema
        from app.tools.sql_executor import execute_sql
        from app.tools.sql_validator import validate_sql

        endpoint = settings.AI_PROJECT_ENDPOINT
        credential = DefaultAzureCredential()

        # FoundryAgent references registered PromptAgents by name
        self._safety = FoundryAgent(
            project_endpoint=endpoint,
            agent_name="inriver-safety",
            credential=credential,
        )

        self._sql_gen = FoundryAgent(
            project_endpoint=endpoint,
            agent_name="inriver-sql-generator",
            credential=credential,
            tools=[get_schema, validate_sql, execute_sql],
        )

        self._formatter = FoundryAgent(
            project_endpoint=endpoint,
            agent_name="inriver-response-formatter",
            credential=credential,
        )

    async def run(
        self, question: str, database: str, schema: str, user_email: str
    ) -> PipelineResult:
        start = time.perf_counter()

        try:
            # Step 1: Safety screening via registered PromptAgent
            safety_result = await self._safety.run(
                f"Check if this input is safe: {question}",
            )
            safety_text = str(safety_result)

            if '"safe": false' in safety_text.lower() or '"safe":false' in safety_text.lower():
                elapsed = (time.perf_counter() - start) * 1000
                return PipelineResult(
                    answer=f"Query rejected: {safety_text}",
                    sql="", database=database, execution_time_ms=elapsed,
                    safe=False, error="Safety check failed",
                )

            # Step 2: SQL generation via registered PromptAgent (with FunctionTools)
            sqlgen_result = await self._sql_gen.run(
                f"User question: {question}\n"
                f"Database: {database}\n"
                f"First call get_schema(database='{database}') to see available tables. "
                f"Then generate a T-SQL SELECT query, validate it with validate_sql, "
                f"and execute it with execute_sql(database='{database}'). "
                f"Include the SQL query and the execution results in your response.",
            )
            sqlgen_text = str(sqlgen_result)

            # Extract SQL from response
            sql = ""
            for line in sqlgen_text.split("\n"):
                stripped = line.strip()
                if stripped.upper().startswith("SELECT") and "FROM" in stripped.upper():
                    sql = stripped
                    break

            # Extract columns/rows from tool results in response
            columns = None
            rows = None
            if '"columns"' in sqlgen_text and '"rows"' in sqlgen_text:
                try:
                    idx = sqlgen_text.index('{"columns"')
                    depth = 0
                    end = idx
                    for i in range(idx, len(sqlgen_text)):
                        if sqlgen_text[i] == '{': depth += 1
                        elif sqlgen_text[i] == '}': depth -= 1
                        if depth == 0:
                            end = i + 1
                            break
                    data = json.loads(sqlgen_text[idx:end])
                    columns = data.get("columns")
                    rows = data.get("rows")
                except (json.JSONDecodeError, ValueError):
                    pass

            # Step 3: Format response via registered PromptAgent
            format_result = await self._formatter.run(
                f"Original question: {question}\n"
                f"SQL executed: {sql}\n"
                f"Results: {json.dumps({'columns': columns, 'rows': rows}) if columns else sqlgen_text}\n"
                f"Format this into a clear, conversational answer.",
            )
            answer = str(format_result)

            elapsed = (time.perf_counter() - start) * 1000
            return PipelineResult(
                answer=answer, sql=sql, database=database,
                execution_time_ms=elapsed, columns=columns, rows=rows,
            )
        except Exception as exc:
            elapsed = (time.perf_counter() - start) * 1000
            return PipelineResult(
                answer=f"Pipeline error: {exc}",
                sql="", database=database,
                execution_time_ms=elapsed, error=str(exc),
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
