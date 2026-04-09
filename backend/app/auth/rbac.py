"""
Role-Based Access Control (RBAC) — Data Isolation Layer
=========================================================
Enforces per-user database permissions for InRiver's multi-tenant environment.

Security rationale:
  Even if every other guardrail is bypassed, this module ensures that a user
  can only ever query databases they have been explicitly granted access to.
  Permissions are loaded from a local JSON file (suitable for demo/PoC) and
  cached in memory.  A SIGHUP signal reloads the file without restarting the
  process, supporting operational key-rotation.

Design choices:
  - Deny by default: unknown users get empty access lists.
  - Case-insensitive email matching: prevents trivial case-swap bypasses.
  - Allowlist of valid database names: the `customer_db` value from a request
    is validated against a hard-coded list before any permission lookup, so
    an attacker cannot supply an arbitrary DB name even if they forge a token.
"""

from __future__ import annotations

import json
import logging
import os
import signal
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

_PERMISSIONS_PATH: Path = Path(__file__).parent / "permissions.json"

# The only valid customer database identifiers this service knows about.
# Any `customer_db` value NOT in this set is rejected outright — even if the
# user's permission record somehow listed it.
VALID_DATABASES: frozenset[str] = frozenset({"acme", "nova", "apex"})

# ---------------------------------------------------------------------------
# In-memory permissions cache
# ---------------------------------------------------------------------------

_permissions_cache: dict[str, Any] = {}


def _load_permissions() -> None:
    """Load (or reload) permissions from the JSON file into the cache."""
    global _permissions_cache
    try:
        with _PERMISSIONS_PATH.open("r", encoding="utf-8") as fh:
            _permissions_cache = json.load(fh)
        logger.info("RBAC permissions loaded from %s", _PERMISSIONS_PATH)
    except FileNotFoundError:
        logger.error(
            "Permissions file not found at %s — all access will be denied.",
            _PERMISSIONS_PATH,
        )
        _permissions_cache = {}
    except json.JSONDecodeError as exc:
        logger.error(
            "Permissions file is malformed (%s) — keeping previous cache.",
            exc,
        )


def _sighup_handler(signum: int, frame: Any) -> None:  # noqa: ARG001
    """Reload permissions on SIGHUP (e.g., after an ops update)."""
    logger.info("SIGHUP received — reloading RBAC permissions.")
    _load_permissions()


# Register the reload handler and perform the initial load at import time.
signal.signal(signal.SIGHUP, _sighup_handler)
_load_permissions()


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


def _get_user_record(user_email: str) -> dict[str, Any] | None:
    """Return the raw permissions record for *user_email* (case-insensitive)."""
    demo_users: dict[str, Any] = _permissions_cache.get("demo_users", {})
    normalized = user_email.strip().lower()
    for stored_email, record in demo_users.items():
        if stored_email.strip().lower() == normalized:
            return record
    return None


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def get_user_databases(user_email: str) -> list[str]:
    """Return the list of database keys the user is allowed to access.

    Args:
        user_email: The authenticated user's email address (from JWT claims).

    Returns:
        A (possibly empty) list of database key strings.  An empty list means
        the user has no access — callers should treat this as a hard deny.
    """
    record = _get_user_record(user_email)
    if record is None:
        logger.debug(
            "RBAC: no permissions record found for '%s' — denying all access.",
            user_email,
        )
        return []
    # Intersect with the allowlist to ensure no stale/invalid entries leak.
    permitted = [db for db in record.get("databases", []) if db in VALID_DATABASES]
    return permitted


def check_database_access(user_email: str, customer_db: str) -> bool:
    """Return True only when *user_email* is explicitly permitted to access *customer_db*.

    Both the user's permission record and the hard-coded allowlist must
    approve the request.

    Args:
        user_email:  The authenticated user's email address.
        customer_db: The customer database key from the incoming request.

    Returns:
        True if access is granted, False otherwise.
    """
    # Step 1 — reject any database name not on the hard allowlist.
    # This prevents privilege escalation via a database name we don't manage.
    if customer_db not in VALID_DATABASES:
        logger.warning(
            "RBAC DENIED: '%s' attempted access to unknown database '%s'.",
            user_email,
            customer_db,
        )
        return False

    # Step 2 — check the user's explicit permission list.
    permitted_dbs = get_user_databases(user_email)
    if customer_db in permitted_dbs:
        logger.debug(
            "RBAC ALLOWED: '%s' → database '%s'.", user_email, customer_db
        )
        return True

    logger.warning(
        "RBAC DENIED: '%s' is not permitted to access database '%s'. "
        "Permitted databases: %s.",
        user_email,
        customer_db,
        permitted_dbs or "(none)",
    )
    return False


def get_user_role(user_email: str) -> str:
    """Return the role string for *user_email*.

    Args:
        user_email: The authenticated user's email address.

    Returns:
        The role string (e.g. "analyst", "admin") or the configured
        ``default_role`` (typically "no_access") when the user is unknown.
    """
    record = _get_user_record(user_email)
    if record is None:
        default: str = _permissions_cache.get("default_role", "no_access")
        return default
    return record.get("role", "no_access")
