from __future__ import annotations

from pydantic import BaseModel, Field


class QueryRequest(BaseModel):
    question: str = Field(..., min_length=1, max_length=2000)
    database: str = Field(..., pattern="^(acme|nova|apex)$")


class QueryResponse(BaseModel):
    answer: str
    sql: str | None = None
    columns: list[str] = []
    rows: list[list] = []
    row_count: int = 0
    execution_time_ms: int = 0
    request_id: str = ""


class ErrorResponse(BaseModel):
    success: bool = False
    message: str
    request_id: str = ""
    can_retry: bool = False


class HealthResponse(BaseModel):
    status: str = "healthy"
    version: str = "0.1.0"


class DatabaseListResponse(BaseModel):
    databases: list[str]
