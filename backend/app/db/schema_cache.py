"""Pre-loaded schema definitions for each tenant database.
In production, this would be loaded from INFORMATION_SCHEMA at startup.
For the PoC, schemas are defined statically (all 3 DBs share the same schema)."""

# The PIM schema shared by all tenant databases
_PIM_SCHEMA = {
    "tables": [
        {
            "name": "Categories",
            "columns": [
                {"name": "CategoryId", "type": "INT"},
                {"name": "CategoryName", "type": "NVARCHAR(200)"},
                {"name": "ParentCategoryId", "type": "INT NULL"},
                {"name": "Description", "type": "NVARCHAR(1000) NULL"},
                {"name": "IsActive", "type": "BIT"},
                {"name": "CreatedDate", "type": "DATETIME2"},
                {"name": "ModifiedDate", "type": "DATETIME2"},
            ],
        },
        {
            "name": "Products",
            "columns": [
                {"name": "ProductId", "type": "INT"},
                {"name": "ProductNumber", "type": "NVARCHAR(50)"},
                {"name": "ProductName", "type": "NVARCHAR(300)"},
                {"name": "Description", "type": "NVARCHAR(4000) NULL"},
                {"name": "CategoryId", "type": "INT"},
                {"name": "Brand", "type": "NVARCHAR(200) NULL"},
                {"name": "Status", "type": "NVARCHAR(50)"},
                {"name": "ListPrice", "type": "DECIMAL(18,2) NULL"},
                {"name": "Currency", "type": "NVARCHAR(3)"},
                {"name": "SKU", "type": "NVARCHAR(100) NULL"},
                {"name": "IsActive", "type": "BIT"},
                {"name": "CreatedDate", "type": "DATETIME2"},
                {"name": "ModifiedDate", "type": "DATETIME2"},
            ],
        },
        {
            "name": "Attributes",
            "columns": [
                {"name": "AttributeId", "type": "INT"},
                {"name": "AttributeName", "type": "NVARCHAR(200)"},
                {"name": "DataType", "type": "NVARCHAR(50)"},
                {"name": "Unit", "type": "NVARCHAR(50) NULL"},
                {"name": "IsRequired", "type": "BIT"},
            ],
        },
        {
            "name": "ProductAttributes",
            "columns": [
                {"name": "ProductAttributeId", "type": "INT"},
                {"name": "ProductId", "type": "INT"},
                {"name": "AttributeId", "type": "INT"},
                {"name": "Value", "type": "NVARCHAR(2000)"},
            ],
        },
        {
            "name": "Customers",
            "columns": [
                {"name": "CustomerId", "type": "INT"},
                {"name": "CustomerName", "type": "NVARCHAR(300)"},
                {"name": "ContactEmail", "type": "NVARCHAR(256) NULL"},
                {"name": "Country", "type": "NVARCHAR(100)"},
                {"name": "Segment", "type": "NVARCHAR(100) NULL"},
                {"name": "IsActive", "type": "BIT"},
                {"name": "CreatedDate", "type": "DATETIME2"},
            ],
        },
        {
            "name": "Orders",
            "columns": [
                {"name": "OrderId", "type": "INT"},
                {"name": "OrderNumber", "type": "NVARCHAR(50)"},
                {"name": "CustomerId", "type": "INT"},
                {"name": "ProductId", "type": "INT"},
                {"name": "Quantity", "type": "INT"},
                {"name": "UnitPrice", "type": "DECIMAL(18,2)"},
                {"name": "TotalAmount", "type": "DECIMAL(18,2)"},
                {"name": "OrderDate", "type": "DATETIME2"},
                {"name": "Status", "type": "NVARCHAR(50)"},
            ],
        },
    ],
    "foreign_keys": [
        {"from_table": "Products", "from_column": "CategoryId", "to_table": "Categories", "to_column": "CategoryId"},
        {"from_table": "ProductAttributes", "from_column": "ProductId", "to_table": "Products", "to_column": "ProductId"},
        {"from_table": "ProductAttributes", "from_column": "AttributeId", "to_table": "Attributes", "to_column": "AttributeId"},
        {"from_table": "Orders", "from_column": "CustomerId", "to_table": "Customers", "to_column": "CustomerId"},
        {"from_table": "Orders", "from_column": "ProductId", "to_table": "Products", "to_column": "ProductId"},
        {"from_table": "Categories", "from_column": "ParentCategoryId", "to_table": "Categories", "to_column": "CategoryId"},
    ],
}

_SCHEMA_CACHE: dict[str, dict] = {
    "acme": _PIM_SCHEMA,
    "nova": _PIM_SCHEMA,
    "apex": _PIM_SCHEMA,
}

def get_schema_for_tenant(tenant_id: str) -> dict | None:
    return _SCHEMA_CACHE.get(tenant_id)

def get_all_tenants() -> list[str]:
    return list(_SCHEMA_CACHE.keys())
