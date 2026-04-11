from jose import jwt

from app.auth.service import validate_password_strength
from app.config import settings
from tests.conftest import _make_expired_token


def test_login_success(test_app):
    resp = test_app.post(
        "/api/v1/auth/login",
        json={"email": "alice@acme.com", "password": "AcmeUser1!"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


def test_login_invalid_password(test_app):
    resp = test_app.post(
        "/api/v1/auth/login",
        json={"email": "alice@acme.com", "password": "wrongpassword"},
    )
    assert resp.status_code == 401


def test_login_unknown_user(test_app):
    resp = test_app.post(
        "/api/v1/auth/login",
        json={"email": "unknown@example.com", "password": "Whatever1!"},
    )
    assert resp.status_code == 401


def test_token_contains_claims(test_app):
    resp = test_app.post(
        "/api/v1/auth/login",
        json={"email": "alice@acme.com", "password": "AcmeUser1!"},
    )
    token = resp.json()["access_token"]
    payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
    assert payload["sub"] == "1"
    assert payload["email"] == "alice@acme.com"
    assert payload["domain"] == "acme.com"
    assert "exp" in payload
    assert "iat" in payload


def test_refresh_token(test_app):
    login_resp = test_app.post(
        "/api/v1/auth/login",
        json={"email": "alice@acme.com", "password": "AcmeUser1!"},
    )
    refresh_token = login_resp.json()["refresh_token"]

    resp = test_app.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data


def test_expired_token(test_app):
    expired = _make_expired_token()
    resp = test_app.get(
        "/api/v1/databases",
        headers={"Authorization": f"Bearer {expired}"},
    )
    assert resp.status_code == 401


def test_password_validation():
    assert validate_password_strength("Abcdefg1") is True
    assert validate_password_strength("short1A") is False  # too short
    assert validate_password_strength("abcdefg1") is False  # no upper
    assert validate_password_strength("ABCDEFG1") is False  # no lower
    assert validate_password_strength("Abcdefgh") is False  # no digit
