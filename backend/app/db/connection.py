from contextlib import asynccontextmanager
from typing import Any, AsyncIterator

import structlog

from app.config import settings

logger = structlog.get_logger()

MOCK_DATA: dict[str, list[dict[str, Any]]] = {
    "Products": [
        {"ProductId": 1, "ProductNumber": "PRD-001", "ProductName": "Widget Pro", "ListPrice": 29.99, "Status": "Published", "IsActive": True},
        {"ProductId": 2, "ProductNumber": "PRD-002", "ProductName": "Gadget Elite", "ListPrice": 49.99, "Status": "Published", "IsActive": True},
        {"ProductId": 3, "ProductNumber": "PRD-003", "ProductName": "Sensor Max", "ListPrice": 19.99, "Status": "Draft", "IsActive": True},
    ],
    "Categories": [
        {"CategoryId": 1, "CategoryName": "Electronics", "ParentCategoryId": None, "IsActive": True},
        {"CategoryId": 2, "CategoryName": "Sensors", "ParentCategoryId": 1, "IsActive": True},
    ],
    "Customers": [
        {"CustomerId": 1, "CustomerName": "TechCorp", "ContactEmail": "info@techcorp.com", "Country": "USA", "Segment": "Enterprise"},
        {"CustomerId": 2, "CustomerName": "RetailMax", "ContactEmail": "info@retailmax.com", "Country": "UK", "Segment": "Retail"},
    ],
    "Orders": [
        {"OrderId": 1, "OrderNumber": "ORD-001", "CustomerId": 1, "ProductId": 1, "Quantity": 100, "UnitPrice": 29.99, "TotalAmount": 2999.00, "Status": "Delivered"},
        {"OrderId": 2, "OrderNumber": "ORD-002", "CustomerId": 2, "ProductId": 2, "Quantity": 50, "UnitPrice": 49.99, "TotalAmount": 2499.50, "Status": "Shipped"},
    ],
}


class MockCursor:
    def __init__(self) -> None:
        self._results: list[dict[str, Any]] = []

    async def execute(self, sql: str) -> None:
        for table_name, rows in MOCK_DATA.items():
            if table_name.lower() in sql.lower():
                self._results = rows
                return
        self._results = []

    async def fetchall(self) -> list[dict[str, Any]]:
        return self._results

    async def close(self) -> None:
        pass


class MockConnection:
    async def cursor(self) -> MockCursor:
        return MockCursor()

    async def close(self) -> None:
        pass


class TenantConnectionManager:
    @asynccontextmanager
    async def get_connection(self, database_name: str) -> AsyncIterator[MockConnection | Any]:
        if settings.USE_MOCK_DB:
            logger.info("using_mock_connection", database=database_name)
            conn = MockConnection()
            try:
                yield conn
            finally:
                await conn.close()
        else:
            # Production: use aioodbc with Azure AD token
            import aioodbc  # type: ignore[import-untyped]

            conn_str = (
                f"DRIVER={{ODBC Driver 18 for SQL Server}};"
                f"SERVER={settings.SQL_SERVER};"
                f"DATABASE={database_name};"
                f"Authentication=ActiveDirectoryDefault;"
            )
            conn = await aioodbc.connect(dsn=conn_str)
            try:
                yield conn
            finally:
                await conn.close()
