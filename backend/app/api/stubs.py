from __future__ import annotations

import logging
from typing import Any

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Auth stub — Linus will replace with real Entra ID JWT validation
# ---------------------------------------------------------------------------
try:
    from app.auth.validator import validate_token  # type: ignore[import]
except ImportError:
    logger.warning("auth.validator not found — using stub validate_token")

    def validate_token(token: str) -> dict[str, Any]:  # type: ignore[misc]
        """Stub: accepts any token and returns a fake claims dict.
        REPLACE with real Entra ID JWT validation before production.
        """
        logger.warning("STUB validate_token called — all tokens accepted")
        return {"sub": "stub-user", "oid": "stub-oid", "email": "stub@example.com", "name": "Stub User"}


# ---------------------------------------------------------------------------
# RBAC — uses app.auth.rbac (real implementation by Linus)
# Falls back to permissive stubs if not available.
# ---------------------------------------------------------------------------
try:
    from app.auth.rbac import check_database_access as _check_database_access
    from app.auth.rbac import get_user_databases as _get_user_databases

    def check_rbac(claims: dict[str, Any], customer_db: str) -> bool:
        """Delegate to real RBAC module using email from JWT claims."""
        user_email: str = claims.get("email") or claims.get("preferred_username") or claims.get("upn") or ""
        return _check_database_access(user_email, customer_db)

    def get_permitted_dbs(claims: dict[str, Any]) -> list[str]:
        """Return databases the user is permitted to access."""
        user_email: str = claims.get("email") or claims.get("preferred_username") or claims.get("upn") or ""
        return _get_user_databases(user_email)

except ImportError:
    logger.warning("auth.rbac not found — using stub RBAC (all access permitted)")

    def check_rbac(claims: dict[str, Any], customer_db: str) -> bool:  # type: ignore[misc]
        logger.warning("STUB check_rbac — all access permitted")
        return True

    def get_permitted_dbs(claims: dict[str, Any]) -> list[str]:  # type: ignore[misc]
        logger.warning("STUB get_permitted_dbs — returning all DBs")
        return ["acme", "nova", "apex"]


# ---------------------------------------------------------------------------
# SQL guardrail — uses app.guardrails.sql_validator (real implementation)
# Falls back to trivial keyword check if not available.
# ---------------------------------------------------------------------------
try:
    from app.guardrails.sql_validator import validate_sql as _real_validate_sql

    def validate_sql(sql: str) -> None:
        """Validate SQL via guardrail module; raise ValueError on rejection."""
        result = _real_validate_sql(sql)
        if not result.is_valid:
            raise ValueError(result.reason or "SQL rejected by guardrails")

except ImportError:
    logger.warning("guardrails.sql_validator not found — using stub validate_sql")

    def validate_sql(sql: str) -> None:  # type: ignore[misc]
        banned = ["insert", "update", "delete", "drop", "create", "alter",
                  "exec", "execute", "truncate", "merge", "grant", "revoke"]
        lowered = sql.lower()
        for keyword in banned:
            if keyword in lowered:
                raise ValueError(f"Query contains forbidden keyword: '{keyword}'")


# ---------------------------------------------------------------------------
# Prompt safety — uses app.guardrails.prompt_safety (real implementation)
# Falls back to no-op if not available.
# ---------------------------------------------------------------------------
try:
    from app.guardrails.prompt_safety import check_prompt_safety as _real_check_prompt_safety

    def check_prompt_safety(question: str) -> None:
        """Check prompt safety; raise ValueError if unsafe."""
        result = _real_check_prompt_safety(question)
        if not result.is_safe:
            raise ValueError(result.reason or "Prompt rejected by safety check")

except ImportError:
    logger.warning("guardrails.prompt_safety not found — using stub check_prompt_safety")

    def check_prompt_safety(question: str) -> None:  # type: ignore[misc]
        logger.warning("STUB check_prompt_safety — no checks applied")

