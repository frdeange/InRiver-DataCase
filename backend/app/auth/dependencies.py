from fastapi import Header, HTTPException

from app.auth.domain_resolver import DomainResolver
from app.auth.models import UserInfo
from app.auth.service import MOCK_USERS, decode_token

domain_resolver = DomainResolver()


async def get_current_user(authorization: str | None = Header(default=None)) -> UserInfo:
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header required")

    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header")

    token = authorization.removeprefix("Bearer ")
    try:
        payload = decode_token(token)
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

    if payload.token_type != "access":
        raise HTTPException(status_code=401, detail="Invalid token type")

    user = MOCK_USERS.get(payload.email)
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")

    databases = domain_resolver.resolve(payload.domain)
    return UserInfo(
        id=user["id"],
        email=user["email"],
        full_name=user["full_name"],
        domain=payload.domain,
        databases=databases,
    )
