import sys
import types
from unittest.mock import MagicMock

# Stub out unavailable packages so modules can be imported in test
for mod_name in (
    "agent_framework",
    "agent_framework.foundry",
    "azure",
    "azure.identity",
):
    if mod_name not in sys.modules:
        sys.modules[mod_name] = types.ModuleType(mod_name)

# Provide minimum stubs expected by app.agents.prompt_safety
_af = sys.modules["agent_framework"]
_af.Agent = MagicMock  # type: ignore[attr-defined]
_af.tool = lambda f: f  # type: ignore[attr-defined]

_aff = sys.modules["agent_framework.foundry"]
_aff.FoundryChatClient = MagicMock  # type: ignore[attr-defined]

_azi = sys.modules["azure.identity"]
_azi.DefaultAzureCredential = MagicMock  # type: ignore[attr-defined]

import pytest
from app.auth.validator import AuthContext


@pytest.fixture
def acme_user() -> AuthContext:
    return AuthContext(
        user_id="user-acme-001",
        username="alice@contoso.com",
        tenant_id="acme",
        roles=frozenset(["Tenant.Acme"]),
        request_id="test-req-001",
    )


@pytest.fixture
def nova_user() -> AuthContext:
    return AuthContext(
        user_id="user-nova-001",
        username="bob@contoso.com",
        tenant_id="nova",
        roles=frozenset(["Tenant.Nova"]),
        request_id="test-req-002",
    )


@pytest.fixture
def admin_user() -> AuthContext:
    return AuthContext(
        user_id="user-admin-001",
        username="admin@contoso.com",
        tenant_id="admin",
        roles=frozenset(["Admin"]),
        request_id="test-req-003",
    )


@pytest.fixture
def no_role_user() -> AuthContext:
    return AuthContext(
        user_id="user-norole-001",
        username="norole@contoso.com",
        tenant_id="",
        roles=frozenset(),
        request_id="test-req-004",
    )


@pytest.fixture
def sample_schema():
    """Schema for db-acme used in SQL validation tests."""
    return {
        "allowed_tables": {"products", "categories", "orders", "customers", "attributes", "productattributes"},
        "allowed_columns": {
            "products": {"productid", "productnumber", "productname", "description", "categoryid", "brand", "status", "listprice", "currency", "sku", "isactive", "createddate", "modifieddate"},
            "categories": {"categoryid", "categoryname", "parentcategoryid", "description", "isactive", "createddate", "modifieddate"},
            "orders": {"orderid", "ordernumber", "customerid", "productid", "quantity", "unitprice", "totalamount", "orderdate", "status"},
            "customers": {"customerid", "customername", "contactemail", "country", "segment", "isactive", "createddate"},
            "attributes": {"attributeid", "attributename", "datatype", "unit", "isrequired"},
            "productattributes": {"productattributeid", "productid", "attributeid", "value"},
        },
    }
