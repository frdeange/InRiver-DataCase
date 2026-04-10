import pytest
from app.auth.rbac import resolve_tenant, get_allowed_tenants


class TestTenantIsolation:
    def test_acme_cannot_access_nova(self):
        tenants = get_allowed_tenants(["Tenant.Acme"])
        assert "nova" not in tenants
        assert "apex" not in tenants

    def test_nova_cannot_access_acme(self):
        tenants = get_allowed_tenants(["Tenant.Nova"])
        assert "acme" not in tenants
        assert "apex" not in tenants

    def test_apex_cannot_access_others(self):
        tenants = get_allowed_tenants(["Tenant.Apex"])
        assert "acme" not in tenants
        assert "nova" not in tenants

    def test_admin_accesses_all(self):
        tenants = get_allowed_tenants(["Admin"])
        assert "acme" in tenants
        assert "nova" in tenants
        assert "apex" in tenants

    def test_no_roles_no_access(self):
        tenants = get_allowed_tenants([])
        assert len(tenants) == 0

    def test_unknown_role_no_access(self):
        tenants = get_allowed_tenants(["Unknown.Role"])
        assert len(tenants) == 0


class TestTenantConnectionIsolation:
    def test_tenant_connection_map(self):
        from app.config import Settings
        s = Settings(
            azure_ai_project_endpoint="https://test",
            sql_conn_acme="acme_conn",
            sql_conn_nova="nova_conn",
            sql_conn_apex="apex_conn",
        )
        assert s.tenant_connections["acme"] == "acme_conn"
        assert s.tenant_connections["nova"] == "nova_conn"
        assert s.tenant_connections["apex"] == "apex_conn"

    def test_no_cross_tenant_connection(self):
        from app.config import Settings
        s = Settings(
            azure_ai_project_endpoint="https://test",
            sql_conn_acme="acme_conn",
        )
        assert s.tenant_connections.get("nova") == ""
