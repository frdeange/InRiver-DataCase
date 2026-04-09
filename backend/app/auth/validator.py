from __future__ import annotations

import logging
import time
from typing import Any

import httpx
from jose import jwt, JWTError, ExpiredSignatureError
from jose.backends import RSAKey

from app.config import get_settings

logger = logging.getLogger(__name__)

# JWKS are cached in-process with a 24-hour TTL.
_jwks_cache: dict[str, Any] | None = None
_jwks_fetched_at: float = 0.0
_JWKS_TTL_SECONDS = 86400  # 24 hours


def _get_jwks() -> dict[str, Any]:
    """Fetch (and cache) the JWKS from Entra ID."""
    global _jwks_cache, _jwks_fetched_at

    now = time.monotonic()
    if _jwks_cache is not None and (now - _jwks_fetched_at) < _JWKS_TTL_SECONDS:
        return _jwks_cache

    settings = get_settings()
    tenant_id = settings.azure_tenant_id
    jwks_url = f"https://login.microsoftonline.com/{tenant_id}/discovery/v2.0/keys"

    logger.info("Fetching JWKS from %s", jwks_url)
    with httpx.Client(timeout=10) as client:
        response = client.get(jwks_url)
        response.raise_for_status()
        _jwks_cache = response.json()
        _jwks_fetched_at = now

    return _jwks_cache


def validate_token(token: str) -> dict[str, Any]:
    """Validate an Entra ID JWT and return the decoded claims dict.

    Validates:
    - Signature (against Entra ID JWKS)
    - Issuer (tenant-specific v2.0 issuer)
    - Audience (must match AZURE_CLIENT_ID)
    - Expiry

    Args:
        token: Raw Bearer token string.

    Returns:
        Decoded JWT claims as a dict.

    Raises:
        ValueError: If the token is invalid, expired, or cannot be verified.
    """
    settings = get_settings()
    tenant_id = settings.azure_tenant_id
    client_id = settings.azure_client_id

    expected_issuer = f"https://login.microsoftonline.com/{tenant_id}/v2.0"

    try:
        # Decode header to find key ID
        unverified_header = jwt.get_unverified_header(token)
        kid = unverified_header.get("kid")
        if not kid:
            raise ValueError("Token header missing 'kid'.")

        jwks = _get_jwks()
        # Find the matching key
        signing_key: dict | None = None
        for key in jwks.get("keys", []):
            if key.get("kid") == kid:
                signing_key = key
                break

        if signing_key is None:
            # Key not found — cache may be stale; force refresh once
            logger.info("kid '%s' not found in JWKS cache — forcing refresh", kid)
            global _jwks_fetched_at
            _jwks_fetched_at = 0.0
            jwks = _get_jwks()
            for key in jwks.get("keys", []):
                if key.get("kid") == kid:
                    signing_key = key
                    break

        if signing_key is None:
            raise ValueError(f"No JWKS key found for kid '{kid}'.")

        claims = jwt.decode(
            token,
            signing_key,
            algorithms=["RS256"],
            audience=client_id,
            issuer=expected_issuer,
            options={"verify_exp": True},
        )
        return claims

    except ExpiredSignatureError as exc:
        raise ValueError("Token has expired.") from exc
    except JWTError as exc:
        raise ValueError(f"Token validation failed: {exc}") from exc
    except Exception as exc:
        raise ValueError(f"Unexpected error validating token: {exc}") from exc
