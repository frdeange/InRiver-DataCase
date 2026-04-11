"""SQL execution tool — mock and production modes."""

from __future__ import annotations

import json
import re


def execute_sql(sql: str, database: str) -> str:
    """Execute validated SQL against the tenant database.

    In mock mode (default) returns sample data based on the query.
    Returns a JSON string with ``columns`` and ``rows``.
    """
    return _mock_execute(sql, database)


def _mock_execute(sql: str, database: str) -> str:
    """Return realistic sample data based on query patterns."""
    upper = sql.upper()

    if re.search(r"COUNT\s*\(", upper):
        return json.dumps(
            {"columns": ["count"], "rows": [[42]], "database": database}
        )

    if "PRODUCTS" in upper and "ORDERS" not in upper:
        return json.dumps(
            {
                "columns": [
                    "ProductId",
                    "ProductNumber",
                    "ProductName",
                    "Status",
                    "ListPrice",
                ],
                "rows": [
                    [1, "PRD-001", "Widget Alpha", "Published", 29.99],
                    [2, "PRD-002", "Widget Beta", "Draft", 49.99],
                    [3, "PRD-003", "Gadget Gamma", "Approved", 99.50],
                ],
                "database": database,
            }
        )

    if "ORDERS" in upper:
        return json.dumps(
            {
                "columns": [
                    "OrderId",
                    "OrderNumber",
                    "CustomerName",
                    "Quantity",
                    "TotalAmount",
                ],
                "rows": [
                    [1, "ORD-1001", "Acme Corp", 10, 299.90],
                    [2, "ORD-1002", "Nova LLC", 5, 249.95],
                ],
                "database": database,
            }
        )

    if "CUSTOMERS" in upper:
        return json.dumps(
            {
                "columns": ["CustomerId", "CustomerName", "Country", "Segment"],
                "rows": [
                    [1, "Acme Corp", "USA", "Enterprise"],
                    [2, "Nova LLC", "Sweden", "SMB"],
                ],
                "database": database,
            }
        )

    if "CATEGORIES" in upper:
        return json.dumps(
            {
                "columns": ["CategoryId", "CategoryName", "IsActive"],
                "rows": [
                    [1, "Electronics", True],
                    [2, "Accessories", True],
                ],
                "database": database,
            }
        )

    # Fallback
    return json.dumps(
        {
            "columns": ["result"],
            "rows": [["Query executed successfully"]],
            "database": database,
        }
    )
