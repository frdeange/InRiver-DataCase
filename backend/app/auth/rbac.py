from __future__ import annotations

ROLE_TO_TENANT: dict[str, str] = {
    "Tenant.Acme": "acme",
    "Tenant.Nova": "nova",
    "Tenant.Apex": "apex",
}


def resolve_tenant(roles: list[str]) -> str:
    """Extract tenant from roles. Exactly one Tenant.* role required."""
    tenants = [ROLE_TO_TENANT[r] for r in roles if r in ROLE_TO_TENANT]
    if "Admin" in roles:
        return "admin"  # admin can access all
    if len(tenants) != 1:
        raise PermissionError("User must have exactly one tenant role")
    return tenants[0]


def get_allowed_tenants(roles: list[str]) -> list[str]:
    if "Admin" in roles:
        return ["acme", "nova", "apex"]
    return [ROLE_TO_TENANT[r] for r in roles if r in ROLE_TO_TENANT]
