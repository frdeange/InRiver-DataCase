from __future__ import annotations

import uuid

import structlog
from fastapi import APIRouter, Depends, HTTPException, status

from app.api.models import (
    DatabaseListResponse,
    ErrorResponse,
    HealthResponse,
    QueryRequest,
    QueryResponse,
)
from app.auth.rbac import get_allowed_tenants
from app.auth.validator import AuthContext, get_auth_context
from app.config import settings

logger = structlog.get_logger(__name__)

router = APIRouter()


# ── Public endpoints ─────────────────────────────────────────────────
@router.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse()


@router.get("/ready", response_model=HealthResponse)
async def ready() -> HealthResponse:
    if not settings.azure_ai_project_endpoint:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Service not configured",
        )
    return HealthResponse(status="ready")


# ── Authenticated endpoints ──────────────────────────────────────────
@router.get("/api/databases", response_model=DatabaseListResponse)
async def list_databases(
    auth: AuthContext = Depends(get_auth_context),
) -> DatabaseListResponse:
    allowed = get_allowed_tenants(list(auth.roles))
    logger.info(
        "databases_listed",
        user_id=auth.user_id,
        request_id=auth.request_id,
        count=len(allowed),
    )
    return DatabaseListResponse(databases=allowed)


@router.post("/api/query", response_model=QueryResponse)
async def query(
    body: QueryRequest,
    auth: AuthContext = Depends(get_auth_context),
) -> QueryResponse | ErrorResponse:
    request_id = str(uuid.uuid4())

    # RBAC check: user must be authorized for the requested database
    allowed = get_allowed_tenants(list(auth.roles))
    if body.database not in allowed:
        logger.warning(
            "unauthorized_database_access",
            user_id=auth.user_id,
            database=body.database,
            request_id=request_id,
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to access this database",
        )

    logger.info(
        "query_received",
        user_id=auth.user_id,
        database=body.database,
        request_id=request_id,
    )

    try:
        from app.agents.orchestrator import orchestrate_query
        from app.observability.audit_logger import AuditLogger

        audit_logger = AuditLogger()
        result = await orchestrate_query(
            question=body.question,
            database=body.database,
            auth_context=auth,
            audit_logger=audit_logger,
        )
        return QueryResponse(
            answer=result.get("answer", ""),
            sql=result.get("sql"),
            columns=result.get("columns", []),
            rows=result.get("rows", []),
            row_count=result.get("row_count", 0),
            execution_time_ms=result.get("execution_time_ms", 0),
            request_id=request_id,
        )
    except Exception:
        logger.exception("query_failed", request_id=request_id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred processing your query",
        )
