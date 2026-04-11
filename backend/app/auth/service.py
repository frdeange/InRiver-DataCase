import re
from datetime import datetime, timedelta, timezone

import bcrypt
from jose import JWTError, jwt

from app.auth.domain_resolver import DomainResolver
from app.auth.models import TokenPayload, UserInfo
from app.config import settings

MOCK_USERS: dict[str, dict] = {
    "alice@acme.com": {
        "id": 1,
        "email": "alice@acme.com",
        "full_name": "Alice Johnson",
        "password_hash": "$2b$12$hxpXvAGW3iONuS2cX9Eft.0IssclhTYom1esha5xIb8OdXN7g2HhG",
    },
    "bob@nova.com": {
        "id": 2,
        "email": "bob@nova.com",
        "full_name": "Bob Smith",
        "password_hash": "$2b$12$ubuSzS3JCJbKJL5Kcn98G.X5zhZ2/ykvbN0.e8lp.l9DE/A5hRpcG",
    },
    "carol@apex.com": {
        "id": 3,
        "email": "carol@apex.com",
        "full_name": "Carol Martinez",
        "password_hash": "$2b$12$5qm4MzrmNhu03UZzLGjWnuwweKpCLnp8Z9WVmGiqAgmlAMueXws3q",
    },
    "admin@inriver.com": {
        "id": 4,
        "email": "admin@inriver.com",
        "full_name": "Admin User",
        "password_hash": "$2b$12$v4Crz8c9FymN/EIk6tGII.HvC40o/K.T1TdixCbFLRygHibFANsNe",
    },
}

domain_resolver = DomainResolver()


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def validate_password_strength(password: str) -> bool:
    if len(password) < 8:
        return False
    if not re.search(r"[A-Z]", password):
        return False
    if not re.search(r"[a-z]", password):
        return False
    if not re.search(r"\d", password):
        return False
    return True


def create_access_token(user_id: int, email: str, domain: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "email": email,
        "domain": domain,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)).timestamp()),
        "token_type": "access",
    }
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


def create_refresh_token(user_id: int, email: str, domain: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "email": email,
        "domain": domain,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)).timestamp()),
        "token_type": "refresh",
    }
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


def decode_token(token: str) -> TokenPayload:
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        return TokenPayload(**payload)
    except JWTError as exc:
        raise ValueError(f"Invalid token: {exc}") from exc


def authenticate_user(email: str, password: str) -> UserInfo | None:
    user = MOCK_USERS.get(email)
    if user is None:
        return None
    if not verify_password(password, user["password_hash"]):
        return None
    domain = email.split("@")[1]
    databases = domain_resolver.resolve(domain)
    return UserInfo(
        id=user["id"],
        email=user["email"],
        full_name=user["full_name"],
        domain=domain,
        databases=databases,
    )
