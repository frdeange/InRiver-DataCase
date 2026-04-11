from datetime import datetime, timedelta, timezone

import pytest
from fastapi.testclient import TestClient
from jose import jwt

from app.auth.service import create_access_token, create_refresh_token
from app.config import settings
from app.main import app


@pytest.fixture
def test_app() -> TestClient:
    return TestClient(app)


@pytest.fixture
def test_user_token() -> str:
    return create_access_token(1, "alice@acme.com", "acme.com")


@pytest.fixture
def admin_user_token() -> str:
    return create_access_token(4, "admin@inriver.com", "inriver.com")


def _make_expired_token() -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": "1",
        "email": "alice@acme.com",
        "domain": "acme.com",
        "iat": int((now - timedelta(hours=2)).timestamp()),
        "exp": int((now - timedelta(hours=1)).timestamp()),
        "token_type": "access",
    }
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
