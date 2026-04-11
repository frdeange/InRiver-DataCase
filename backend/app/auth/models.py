from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class UserInfo(BaseModel):
    id: int
    email: str
    full_name: str
    domain: str
    databases: list[str]


class TokenPayload(BaseModel):
    sub: str
    email: str
    domain: str
    exp: int
    iat: int
    token_type: str
