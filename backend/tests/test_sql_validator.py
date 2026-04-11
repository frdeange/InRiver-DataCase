from app.guardrails.sql_validator import SQLValidator

validator = SQLValidator()


def test_valid_select():
    ok, reason = validator.validate("SELECT * FROM Products")
    assert ok is True


def test_select_with_join():
    sql = """
    SELECT p.ProductName, c.CategoryName
    FROM Products p
    JOIN Categories c ON p.CategoryId = c.CategoryId
    """
    ok, reason = validator.validate(sql)
    assert ok is True


def test_select_with_cte():
    sql = """
    WITH ActiveProducts AS (
        SELECT ProductId, ProductName FROM Products WHERE IsActive = 1
    )
    SELECT * FROM ActiveProducts
    """
    ok, reason = validator.validate(sql)
    assert ok is True


def test_select_with_subquery():
    sql = """
    SELECT * FROM Products
    WHERE CategoryId IN (SELECT CategoryId FROM Categories WHERE IsActive = 1)
    """
    ok, reason = validator.validate(sql)
    assert ok is True


def test_reject_insert():
    ok, reason = validator.validate("INSERT INTO Products (ProductName) VALUES ('Test')")
    assert ok is False
    assert "Insert" in reason or "not allowed" in reason.lower()


def test_reject_update():
    ok, reason = validator.validate("UPDATE Products SET ProductName = 'Test' WHERE ProductId = 1")
    assert ok is False


def test_reject_delete():
    ok, reason = validator.validate("DELETE FROM Products WHERE ProductId = 1")
    assert ok is False


def test_reject_drop():
    ok, reason = validator.validate("DROP TABLE Products")
    assert ok is False


def test_reject_alter():
    ok, reason = validator.validate("ALTER TABLE Products ADD NewColumn INT")
    assert ok is False


def test_reject_multiple_statements():
    ok, reason = validator.validate("SELECT 1; DROP TABLE Products")
    assert ok is False
    assert "Multiple" in reason or "not allowed" in reason.lower()
