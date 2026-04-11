"""Tests for the mock orchestration pipeline."""

from __future__ import annotations

import pytest

from app.pipeline import MockPipeline


@pytest.fixture
def pipeline() -> MockPipeline:
    return MockPipeline()


@pytest.mark.asyncio
async def test_safe_query_processed(pipeline: MockPipeline) -> None:
    """A safe natural-language query should return a valid answer."""
    result = await pipeline.run(
        question="Show all products",
        database="db-acme",
        schema="",
        user_email="user@example.com",
    )
    assert result.safe is True
    assert result.answer
    assert result.error is None


@pytest.mark.asyncio
async def test_unsafe_query_rejected(pipeline: MockPipeline) -> None:
    """An injection attempt should be flagged as unsafe."""
    result = await pipeline.run(
        question="'; DROP TABLE Products; --",
        database="db-acme",
        schema="",
        user_email="user@example.com",
    )
    assert result.safe is False
    assert "rejected" in result.answer.lower() or "injection" in result.answer.lower()


@pytest.mark.asyncio
async def test_pipeline_returns_sql(pipeline: MockPipeline) -> None:
    """The pipeline result should include the generated SQL."""
    result = await pipeline.run(
        question="List all orders",
        database="db-acme",
        schema="",
        user_email="user@example.com",
    )
    assert result.sql
    assert "SELECT" in result.sql.upper()
    assert result.database == "db-acme"
    assert result.execution_time_ms >= 0
