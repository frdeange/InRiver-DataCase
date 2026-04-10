import pytest
from app.auth.rbac import resolve_tenant, get_allowed_tenants


class TestResolveTenant:
    def test_acme_role(self):
        assert resolve_tenant(["Tenant.Acme"]) == "acme"

    def test_nova_role(self):
        assert resolve_tenant(["Tenant.Nova"]) == "nova"

    def test_apex_role(self):
        assert resolve_tenant(["Tenant.Apex"]) == "apex"

    def test_admin_role(self):
        assert resolve_tenant(["Admin"]) == "admin"

    def test_no_role_raises(self):
        with pytest.raises(PermissionError):
            resolve_tenant([])

    def test_unknown_role_raises(self):
        with pytest.raises(PermissionError):
            resolve_tenant(["SomeOther.Role"])

    def test_multiple_tenant_roles_raises(self):
        with pytest.raises(PermissionError):
            resolve_tenant(["Tenant.Acme", "Tenant.Nova"])


class TestGetAllowedTenants:
    def test_acme_user(self):
        assert get_allowed_tenants(["Tenant.Acme"]) == ["acme"]

    def test_admin_gets_all(self):
        result = get_allowed_tenants(["Admin"])
        assert set(result) == {"acme", "nova", "apex"}

    def test_no_roles(self):
        assert get_allowed_tenants([]) == []
