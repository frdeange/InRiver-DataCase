import pytest
from app.agents.sql_validator import validate_sql


class TestValidSQL:
    def test_simple_select(self, sample_schema):
        result = validate_sql(
            "SELECT ProductName, ListPrice FROM Products WHERE Status = 'Published'",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is True
        assert "TOP 500" in result["sanitized_sql"]

    def test_select_with_join(self, sample_schema):
        result = validate_sql(
            "SELECT p.ProductName, c.CategoryName FROM Products p JOIN Categories c ON p.CategoryId = c.CategoryId",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is True

    def test_select_with_top(self, sample_schema):
        result = validate_sql(
            "SELECT TOP 10 ProductName FROM Products",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is True
        assert result["sanitized_sql"].startswith("SELECT TOP 10")

    def test_aggregate_query(self, sample_schema):
        result = validate_sql(
            "SELECT COUNT(ProductId) AS TotalProducts FROM Products",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is True

    def test_group_by(self, sample_schema):
        result = validate_sql(
            "SELECT Brand, COUNT(ProductId) AS cnt FROM Products GROUP BY Brand",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is True


class TestBlockedSQL:
    def test_drop_table(self, sample_schema):
        result = validate_sql(
            "DROP TABLE Products",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False
        assert any("DROP" in v for v in result["violations"])

    def test_insert(self, sample_schema):
        result = validate_sql(
            "INSERT INTO Products (ProductName) VALUES ('hack')",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False

    def test_update(self, sample_schema):
        result = validate_sql(
            "UPDATE Products SET ListPrice = 0",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False

    def test_delete(self, sample_schema):
        result = validate_sql(
            "DELETE FROM Products",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False

    def test_truncate(self, sample_schema):
        result = validate_sql(
            "TRUNCATE TABLE Products",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False

    def test_exec(self, sample_schema):
        result = validate_sql(
            "EXEC xp_cmdshell 'whoami'",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False

    def test_multi_statement(self, sample_schema):
        result = validate_sql(
            "SELECT 1; DROP TABLE Products",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False

    def test_cross_database(self, sample_schema):
        result = validate_sql(
            "SELECT ProductName FROM nova_db.dbo.Products",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False
        assert any("CROSS_DATABASE" in v for v in result["violations"])

    def test_system_tables(self, sample_schema):
        result = validate_sql(
            "SELECT name FROM sys.tables",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False

    def test_information_schema(self, sample_schema):
        result = validate_sql(
            "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False

    def test_openrowset(self, sample_schema):
        result = validate_sql(
            "SELECT * FROM OPENROWSET('SQLNCLI', 'server=evil;', 'SELECT 1')",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False

    def test_union_injection(self, sample_schema):
        result = validate_sql(
            "SELECT ProductName FROM Products UNION SELECT password FROM sys.sql_logins",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False

    def test_select_star(self, sample_schema):
        result = validate_sql(
            "SELECT * FROM Products",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False
        assert any("SELECT_STAR" in v for v in result["violations"])

    def test_unauthorized_table(self, sample_schema):
        result = validate_sql(
            "SELECT id FROM evil_table",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False
        assert any("UNAUTHORIZED_TABLE" in v for v in result["violations"])

    def test_sql_comments(self, sample_schema):
        result = validate_sql(
            "SELECT ProductName FROM Products -- drop table hack",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False

    def test_use_statement(self, sample_schema):
        result = validate_sql(
            "USE nova_db; SELECT 1",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False

    def test_waitfor(self, sample_schema):
        result = validate_sql(
            "SELECT 1; WAITFOR DELAY '00:00:05'",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False

    def test_empty_sql(self, sample_schema):
        result = validate_sql(
            "",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False

    def test_declare_variable(self, sample_schema):
        result = validate_sql(
            "DECLARE @x INT; SELECT @x = 1",
            "acme", sample_schema["allowed_tables"], sample_schema["allowed_columns"]
        )
        assert result["is_valid"] is False
