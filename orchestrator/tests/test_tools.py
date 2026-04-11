"""Tests for FunctionTools (sql_validator, schema_provider, sql_executor)."""

from __future__ import annotations

import json

from app.tools.schema_provider import get_schema
from app.tools.sql_executor import execute_sql
from app.tools.sql_validator import validate_sql


def test_validate_select() -> None:
    """A plain SELECT statement should pass validation."""
    result = json.loads(validate_sql("SELECT * FROM Products"))
    assert result["valid"] is True


def test_validate_insert_rejected() -> None:
    """INSERT statements must be rejected."""
    result = json.loads(
        validate_sql("INSERT INTO Products (ProductName) VALUES ('x')")
    )
    assert result["valid"] is False
    assert "INSERT" in result["reason"].upper()


def test_validate_drop_rejected() -> None:
    """DROP statements must be rejected."""
    result = json.loads(validate_sql("DROP TABLE Products"))
    assert result["valid"] is False
    assert "DROP" in result["reason"].upper()


def test_schema_provider_returns_schema() -> None:
    """get_schema should return content containing CREATE TABLE."""
    schema = get_schema("db-acme")
    assert "CREATE TABLE" in schema
    assert "Products" in schema


def test_sql_executor_mock() -> None:
    """Mock executor should return sample product data."""
    raw = execute_sql(
        "SELECT p.ProductId, p.ProductName FROM Products p", "db-acme"
    )
    data = json.loads(raw)
    assert "columns" in data
    assert "rows" in data
    assert len(data["rows"]) > 0
    assert data["database"] == "db-acme"
