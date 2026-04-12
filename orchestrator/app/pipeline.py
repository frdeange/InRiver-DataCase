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
    """Production pipeline: FoundryAgent + MCPStreamableHTTPTool + SequentialBuilder.

    All agents are FoundryAgent (registered PromptAgents in Azure AI Foundry).
    SQL tools are served by a remote MCP server (FastMCP on a separate ACA).
    SequentialBuilder orchestrates: Safety → SQLGenerator → Formatter.
    """

    def __init__(self) -> None:
        from agent_framework import MCPStreamableHTTPTool
        from agent_framework.foundry import FoundryAgent
        from agent_framework.orchestrations import SequentialBuilder
        from azure.identity import DefaultAzureCredential

        endpoint = settings.AI_PROJECT_ENDPOINT
        credential = DefaultAzureCredential()

        # MCP tool connecting to the remote SQL tools server
        self._mcp_tool = MCPStreamableHTTPTool(
            name="sql-tools",
            url=settings.MCP_TOOLS_URL,
        )

        # All agents are FoundryAgent — registered PromptAgents in AI Foundry
        self._safety = FoundryAgent(
            project_endpoint=endpoint,
            agent_name="inriver-safety",
            credential=credential,
        )

        self._sql_gen = FoundryAgent(
            project_endpoint=endpoint,
            agent_name="inriver-sql-generator",
            credential=credential,
            tools=[self._mcp_tool],
            instructions=(
                "You are a SQL generation agent for the InRiver DataCase PIM system.\n"
                "You have MCP tools available. You MUST follow these steps:\n"
                "1. Call get_schema(database=<db>) to see available tables and columns\n"
                "2. Generate a T-SQL SELECT query based on the user's question and the schema\n"
                "3. Call validate_sql(sql=<query>) to verify it is safe\n"
                "4. Call execute_sql(sql=<query>, database=<db>) to run it\n"
                "5. Include the SQL query and the full results in your response\n"
                "IMPORTANT: Always call all tools. The database name is in the user's message."
            ),
        )

        self._formatter = FoundryAgent(
            project_endpoint=endpoint,
            agent_name="inriver-response-formatter",
            credential=credential,
        )

        # MAF SequentialBuilder: Safety → SQLGenerator (with MCP tools) → Formatter
        self._workflow = SequentialBuilder(
            participants=[self._safety, self._sql_gen, self._formatter],
            intermediate_outputs=True,
        ).build()

    async def run(
        self, question: str, database: str, schema: str, user_email: str
    ) -> PipelineResult:
        start = time.perf_counter()

        prompt = (
            f"User question: {question}\n"
            f"Database: {database}\n"
            f"Instructions: First check safety. If safe, generate a T-SQL SELECT query "
            f"using get_schema(database='{database}'), validate with validate_sql, "
            f"execute with execute_sql(database='{database}'), then format the results."
        )

        try:
            # Run the sequential workflow
            result = await self._workflow.run(prompt)

            # Extract data from the workflow result
            answer = ""
            sql = ""
            columns = None
            rows = None

            # Walk through workflow events to extract SQL and data
            for event in result:
                event_str = str(event)

                # Extract SQL
                if not sql:
                    for line in event_str.split("\n"):
                        stripped = line.strip()
                        if stripped.upper().startswith("SELECT") and "FROM" in stripped.upper():
                            sql = stripped
                            break

                # Extract columns/rows from tool results
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

            # Final output is the formatter's response (last in the sequence)
            outputs = result.get_outputs()
            if outputs:
                last = outputs[-1] if isinstance(outputs, list) else outputs
                if isinstance(last, list):
                    # Get last assistant message from the formatter
                    for msg in reversed(last):
                        if hasattr(msg, 'role') and msg.role == 'assistant':
                            raw = msg.text or str(msg)
                            # Clean up: remove tool call artifacts from the answer
                            # The sequential output may contain intermediate tool calls
                            clean_lines = []
                            for line in raw.split("\n"):
                                # Skip lines that are tool call artifacts
                                if line.strip().startswith("to=") or line.strip().startswith('{"database"') or line.strip().startswith('{"sql"'):
                                    continue
                                clean_lines.append(line)
                            answer = "\n".join(clean_lines).strip()
                            if answer:
                                break
                else:
                    raw = str(last)
                    clean_lines = []
                    for line in raw.split("\n"):
                        if line.strip().startswith("to=") or line.strip().startswith('{"database"') or line.strip().startswith('{"sql"'):
                            continue
                        clean_lines.append(line)
                    answer = "\n".join(clean_lines).strip()

            if not answer:
                answer = "The query was processed but no formatted response was generated."

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
