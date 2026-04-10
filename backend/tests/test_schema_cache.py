from app.db.schema_cache import get_schema_for_tenant, get_all_tenants


class TestSchemaCache:
    def test_acme_schema_exists(self):
        schema = get_schema_for_tenant("acme")
        assert schema is not None
        assert len(schema["tables"]) == 6

    def test_all_tenants(self):
        tenants = get_all_tenants()
        assert set(tenants) == {"acme", "nova", "apex"}

    def test_unknown_tenant(self):
        assert get_schema_for_tenant("unknown") is None

    def test_schema_tables(self):
        schema = get_schema_for_tenant("acme")
        table_names = {t["name"] for t in schema["tables"]}
        assert "Products" in table_names
        assert "Categories" in table_names
        assert "Orders" in table_names

    def test_foreign_keys(self):
        schema = get_schema_for_tenant("acme")
        fk_pairs = [(fk["from_table"], fk["to_table"]) for fk in schema["foreign_keys"]]
        assert ("Products", "Categories") in fk_pairs
        assert ("Orders", "Customers") in fk_pairs
