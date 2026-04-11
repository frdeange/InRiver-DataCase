from __future__ import annotations

import time
import uuid
from dataclasses import dataclass

import httpx
import structlog
from fastapi import Depends, HTTPException, Request, status
from jose import JWTError, jwt

from app.auth.rbac import resolve_tenant
from app.config import settings

logger = structlog.get_logger(__name__)

# ── JWKS cache ───────────────────────────────────────────────────────
_jwks_cache: dict | None = None
_jwks_cache_ts: float = 0.0
_JWKS_TTL_SECONDS: float = 86_400  # 24 h


async def _fetch_jwks() -> dict:
    """Download the JWKS key set from Entra ID."""
    global _jwks_cache, _jwks_cache_ts  # noqa: PLW0603

    now = time.monotonic()
    if _jwks_cache is not None and (now - _jwks_cache_ts) < _JWKS_TTL_SECONDS:
        return _jwks_cache

    url = (
        f"https://login.microsoftonline.com/"
        f"{settings.azure_tenant_id}/discovery/v2.0/keys"
    )
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(url)
            resp.raise_for_status()
            _jwks_cache = resp.json()
            _jwks_cache_ts = now
            logger.info("jwks_refreshed", tenant_id=settings.azure_tenant_id)
            return _jwks_cache
    except Exception:
        logger.warning("jwks_fetch_failed", tenant_id=settings.azure_tenant_id)
        if _jwks_cache is not None:
            return _jwks_cache  # return stale cache
        raise


def _get_signing_key(jwks: dict, token: str) -> dict:
    """Find the signing key that matches the token's kid header."""
    unverified_header = jwt.get_unverified_header(token)
    kid = unverified_header.get("kid")
    for key in jwks.get("keys", []):
        if key.get("kid") == kid:
            return key
    raise JWTError("No matching signing key found")


# ── AuthContext ──────────────────────────────────────────────────────
@dataclass(frozen=True)
class AuthContext:
    user_id: str  # oid
    username: str  # preferred_username
    tenant_id: str  # resolved from roles
    roles: frozenset[str]
    request_id: str


# ── FastAPI dependency ───────────────────────────────────────────────
async def get_auth_context(request: Request) -> AuthContext:
    """Validate the Bearer JWT and return an AuthContext."""
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid authorization header",
        )

    token = auth_header[7:]
    request_id = str(uuid.uuid4())

    try:
        jwks = await _fetch_jwks()
        signing_key = _get_signing_key(jwks, token)

        # Decode without verification first to inspect claims for debugging
        unverified = jwt.get_unverified_claims(token)
        token_aud = unverified.get("aud")
        token_iss = unverified.get("iss")
        token_ver = unverified.get("ver")
        logger.info(
            "token_claims_debug",
            aud=token_aud,
            iss=token_iss,
            ver=token_ver,
            expected_aud=[
                settings.azure_client_id,
                f"api://{settings.azure_client_id}",
            ],
            request_id=request_id,
        )

        # v1 tokens use a different issuer format than v2
        issuers = [
            f"https://login.microsoftonline.com/{settings.azure_tenant_id}/v2.0",
            f"https://sts.windows.net/{settings.azure_tenant_id}/",
        ]

        payload = jwt.decode(
            token,
            signing_key,
            algorithms=["RS256"],
            audience=f"api://{settings.azure_client_id}",
            issuer=issuers,
            options={"verify_iss": True},
        )
    except JWTError as e:
        logger.warning("jwt_validation_failed", request_id=request_id, error=str(e))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
    except Exception as e:
        logger.warning("auth_error", request_id=request_id, error=str(e))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed",
        )

    roles = payload.get("roles", [])
    try:
        resolved_tenant = resolve_tenant(roles)
    except PermissionError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient permissions",
        )

    return AuthContext(
        user_id=payload.get("oid", ""),
        username=payload.get("preferred_username", ""),
        tenant_id=resolved_tenant,
        roles=frozenset(roles),
        request_id=request_id,
    )
