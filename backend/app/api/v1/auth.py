from fastapi import APIRouter, HTTPException

from app.auth.models import LoginRequest, RefreshRequest, TokenResponse
from app.auth.service import (
    authenticate_user,
    create_access_token,
    create_refresh_token,
    decode_token,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse)
async def login(request: LoginRequest) -> TokenResponse:
    user = authenticate_user(request.email, request.password)
    if user is None:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    access_token = create_access_token(user.id, user.email, user.domain)
    refresh_token = create_refresh_token(user.id, user.email, user.domain)
    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(request: RefreshRequest) -> TokenResponse:
    try:
        payload = decode_token(request.refresh_token)
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    if payload.token_type != "refresh":
        raise HTTPException(status_code=401, detail="Invalid token type")

    access_token = create_access_token(int(payload.sub), payload.email, payload.domain)
    refresh_token = create_refresh_token(int(payload.sub), payload.email, payload.domain)
    return TokenResponse(access_token=access_token, refresh_token=refresh_token)
