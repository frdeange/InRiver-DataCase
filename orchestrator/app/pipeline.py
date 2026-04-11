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

        # Step 5: Formatting
        answer = self._format_response(question, sql, raw_data)

        elapsed = (time.perf_counter() - start) * 1000
        return PipelineResult(
            answer=answer,
            sql=sql,
            database=database,
            execution_time_ms=elapsed,
        )


# ---------------------------------------------------------------------------
# Real pipeline — requires Azure AI Foundry
# ---------------------------------------------------------------------------


class RealPipeline(BasePipeline):
    """Production pipeline using FoundryAgent + HandoffBuilder."""

    def __init__(self) -> None:
        from agent_framework.orchestrations import HandoffBuilder

        from app.agents.formatter import create_formatter_agent
        from app.agents.safety import create_safety_agent
        from app.agents.sql_generator import create_sql_generator_agent

        endpoint = settings.AI_PROJECT_ENDPOINT

        self._safety = create_safety_agent(endpoint)
        self._sql_gen = create_sql_generator_agent(endpoint)
        self._formatter = create_formatter_agent(endpoint)

        self._orchestrator = HandoffBuilder(
            name="inriver-orchestrator",
            participants=[self._safety, self._sql_gen, self._formatter],
        )

    async def run(
        self, question: str, database: str, schema: str, user_email: str
    ) -> PipelineResult:
        start = time.perf_counter()

        prompt = (
            f"User ({user_email}) asked: {question}\n"
            f"Database: {database}\n"
            f"Schema:\n{schema}\n"
        )

        result = await self._orchestrator.run(prompt)  # type: ignore[attr-defined]

        elapsed = (time.perf_counter() - start) * 1000
        return PipelineResult(
            answer=str(result),
            sql="",
            database=database,
            execution_time_ms=elapsed,
        )


# ---------------------------------------------------------------------------
# Factory
# ---------------------------------------------------------------------------

_pipeline: BasePipeline | None = None


def get_pipeline() -> BasePipeline:
    """Return a pipeline instance (mock or real) based on config."""
    global _pipeline  # noqa: PLW0603
    if _pipeline is None:
        if settings.USE_MOCK_DB:
            _pipeline = MockPipeline()
        else:
            _pipeline = RealPipeline()
    return _pipeline
