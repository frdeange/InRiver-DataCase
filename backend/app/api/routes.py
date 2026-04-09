from __future__ import annotations

import base64
import json
import logging
import time
from typing import Any

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, Field

from app.agents.schema_context import SCHEMA_CONTEXT, build_schema_string
from app.agents.sql_agent import generate_sql
from app.auth.rbac import check_database_access, get_user_databases
from app.config import get_settings
from app.db.connection import execute_query, get_available_databases
from app.guardrails.prompt_safety import check_prompt_safety
from app.guardrails.sql_validator import validate_sql
from app.observability.audit_logger import log_query_event

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["query"])


# ---------------------------------------------------------------------------
# Request / response models
# ---------------------------------------------------------------------------


class QueryRequest(BaseModel):
    question: str = Field(..., description="Natural-language question about the PIM data")
    customer_db: str = Field(..., description="Target customer database key: 'acme', 'nova', or 'apex'")
    user: str = Field(default="", description="User email (fallback when no JWT is present)")


class QueryResponse(BaseModel):
    question: str
    customer_db: str
    generated_sql: str
    results: list[dict[str, Any]]
    row_count: int
    guardrail_passed: bool
    risk_level: str
    blocked: bool
    block_reason: str | None
    duration_ms: float


class DatabasesResponse(BaseModel):
    databases: list[str]


class SchemaResponse(BaseModel):
    tables: list[str]


# ---------------------------------------------------------------------------
# Auth helper
# ---------------------------------------------------------------------------


def extract_user(request: Request, body_user: str = "") -> str:
    """Resolve the acting user from (in priority order):
    1. Authorization: Bearer <JWT> — base64-decode the payload to read `preferred_username`.
       NOTE: Production MUST verify the signature via Entra ID JWKS.  This demo
       skips signature verification for simplicity.
    2. Query parameter ?user=
    3. Request body .user field
    """
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        token = auth_header.removeprefix("Bearer ").strip()
        try:
            parts = token.split(".")
            if len(parts) >= 2:
                # Pad to a valid base64 length
                payload_b64 = parts[1] + "=" * (-len(parts[1]) % 4)
                payload = json.loads(base64.urlsafe_b64decode(payload_b64))
                email = (
                    payload.get("preferred_username")
                    or payload.get("email")
                    or payload.get("upn")
                    or ""
                )
                if email:
                    return str(email)
        except Exception:
            pass  # Fall through to query param / body

    # Fall back to query param ?user=
    query_user = request.query_params.get("user", "")
    if query_user:
        return query_user

    # Fall back to body field
    return body_user


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------


@router.get("/databases", response_model=DatabasesResponse)
async def list_databases(request: Request) -> DatabasesResponse:
    """Return databases the authenticated user is permitted to access."""
    user = extract_user(request)
    permitted = get_user_databases(user)
    return DatabasesResponse(databases=permitted)


@router.post("/query", response_model=QueryResponse)
async def query(body: QueryRequest, request: Request) -> QueryResponse:
    """Translate a natural-language question into SQL, execute it, and return results."""
    start = time.perf_counter()
    user = extract_user(request, body.user)

    def _blocked(reason: str, risk: str = "high") -> QueryResponse:
        duration = (time.perf_counter() - start) * 1000
        return QueryResponse(
            question=body.question,
            customer_db=body.customer_db,
            generated_sql="",
            results=[],
            row_count=0,
            guardrail_passed=False,
            risk_level=risk,
            blocked=True,
            block_reason=reason,
            duration_ms=round(duration, 2),
        )

    # 1. Prompt safety
    safety_result = check_prompt_safety(body.question)
    if not safety_result.is_safe:
        log_query_event(
            user_email=user,
            customer_db=body.customer_db,
            user_question=body.question,
            generated_sql=None,
            validation_result=None,
            prompt_safety_result=safety_result,
            execution_success=False,
            row_count=None,
            error=safety_result.reason,
            duration_ms=(time.perf_counter() - start) * 1000,
        )
        return _blocked(safety_result.reason or "Prompt rejected.", safety_result.risk_level)

    # 2. RBAC
    if not check_database_access(user, body.customer_db):
        log_query_event(
            user_email=user,
            customer_db=body.customer_db,
            user_question=body.question,
            generated_sql=None,
            validation_result=None,
            prompt_safety_result=safety_result,
            execution_success=False,
            row_count=None,
            error="Access denied.",
            duration_ms=(time.perf_counter() - start) * 1000,
        )
        raise HTTPException(status_code=403, detail="Access to this database is not permitted.")

    # 3. Generate SQL
    try:
        schema_hint = build_schema_string()
        generated_sql = generate_sql(body.question, body.customer_db, schema_hint)
    except Exception as exc:
        logger.exception("SQL generation error")
        return _blocked(f"SQL generation error: {exc}")

    # 4. Validate SQL
    validation_result = validate_sql(generated_sql)
    if not validation_result.is_valid:
        log_query_event(
            user_email=user,
            customer_db=body.customer_db,
            user_question=body.question,
            generated_sql=generated_sql,
            validation_result=validation_result,
            prompt_safety_result=safety_result,
            execution_success=False,
            row_count=None,
            error=validation_result.reason,
            duration_ms=(time.perf_counter() - start) * 1000,
        )
        return _blocked(validation_result.reason or "SQL rejected.", validation_result.risk_level)

    # 5. Execute query
    results: list[dict[str, Any]] = []
    error: str | None = None
    execution_success = False
    try:
        results = execute_query(body.customer_db, generated_sql)
        execution_success = True
    except Exception as exc:
        logger.exception("Query execution error")
        error = "Query execution failed."

    duration_ms = round((time.perf_counter() - start) * 1000, 2)

    # 6. Audit log
    log_query_event(
        user_email=user,
        customer_db=body.customer_db,
        user_question=body.question,
        generated_sql=generated_sql,
        validation_result=validation_result,
        prompt_safety_result=safety_result,
        execution_success=execution_success,
        row_count=len(results),
        error=error,
        duration_ms=duration_ms,
    )

    if not execution_success:
        return QueryResponse(
            question=body.question,
            customer_db=body.customer_db,
            generated_sql=generated_sql,
            results=[],
            row_count=0,
            guardrail_passed=True,
            risk_level=validation_result.risk_level,
            blocked=True,
            block_reason=error,
            duration_ms=duration_ms,
        )

    return QueryResponse(
        question=body.question,
        customer_db=body.customer_db,
        generated_sql=generated_sql,
        results=results,
        row_count=len(results),
        guardrail_passed=True,
        risk_level=validation_result.risk_level,
        blocked=False,
        block_reason=None,
        duration_ms=duration_ms,
    )


@router.get("/schema/{customer_db}", response_model=SchemaResponse)
async def get_schema(customer_db: str) -> SchemaResponse:
    """Return a summary of available tables for the given customer database."""
    if customer_db not in get_available_databases():
        raise HTTPException(status_code=404, detail=f"Unknown database: '{customer_db}'")
    return SchemaResponse(tables=list(SCHEMA_CONTEXT.keys()))
