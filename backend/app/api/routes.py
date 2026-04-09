from __future__ import annotations

import logging
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Header
from pydantic import BaseModel, Field

from app.config import get_settings
from app.agents.sql_agent import run_sql_agent
from app.agents.schema_context import SCHEMA_CONTEXT
from app.api.stubs import validate_token, check_rbac, get_permitted_dbs, validate_sql, check_prompt_safety

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["query"])

# ---------------------------------------------------------------------------
# Request / response models
# ---------------------------------------------------------------------------


class QueryRequest(BaseModel):
    question: str = Field(..., min_length=1, description="Natural-language question about the PIM data")
    customer_db: str = Field(..., description="Target customer database key: 'acme', 'nova', or 'apex'")


class QueryResponse(BaseModel):
    sql: str
    explanation: str
    results: list[dict[str, Any]]
    row_count: int


class DatabasesResponse(BaseModel):
    databases: list[str]


class SchemaResponse(BaseModel):
    tables: list[dict[str, Any]]


# ---------------------------------------------------------------------------
# Auth dependency
# ---------------------------------------------------------------------------


def _get_claims(authorization: str = Header(..., alias="Authorization")) -> dict[str, Any]:
    """Extract and validate the Bearer token from the Authorization header."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid Authorization header format. Expected 'Bearer <token>'.")
    token = authorization.removeprefix("Bearer ").strip()
    try:
        return validate_token(token)
    except Exception as exc:
        logger.warning("Token validation failed: %s", exc)
        raise HTTPException(status_code=401, detail="Invalid or expired token.") from exc


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------


@router.post("/query", response_model=QueryResponse)
async def query(
    body: QueryRequest,
    claims: dict[str, Any] = Depends(_get_claims),
) -> QueryResponse:
    """Translate a natural-language question into SQL, execute it, and return results."""
    settings = get_settings()

    # 1. Question length guard
    if len(body.question) > settings.max_query_length:
        raise HTTPException(
            status_code=400,
            detail=f"Question exceeds maximum length of {settings.max_query_length} characters.",
        )

    # 2. RBAC — check user is permitted to access the requested DB
    if not check_rbac(claims, body.customer_db):
        raise HTTPException(
            status_code=403,
            detail=f"Access to database '{body.customer_db}' is not permitted for this user.",
        )

    # 3. Prompt safety check
    try:
        check_prompt_safety(body.question)
    except ValueError as exc:
        raise HTTPException(status_code=403, detail=f"Question rejected by safety check: {exc}") from exc

    # 4. AI agent: generate SQL
    try:
        result = run_sql_agent(
            question=body.question,
            customer_db=body.customer_db,
            sql_validator=validate_sql,
        )
    except ValueError as exc:
        # Guardrail rejection
        raise HTTPException(status_code=403, detail=str(exc)) from exc
    except RuntimeError as exc:
        logger.error("SQL agent error: %s", exc)
        raise HTTPException(status_code=502, detail=f"AI agent error: {exc}") from exc
    except Exception as exc:
        logger.exception("Unexpected error in SQL agent")
        raise HTTPException(status_code=500, detail="Internal server error.") from exc

    return QueryResponse(**result)


@router.get("/databases", response_model=DatabasesResponse)
async def list_databases(
    claims: dict[str, Any] = Depends(_get_claims),
) -> DatabasesResponse:
    """Return the list of customer databases the authenticated user is permitted to access."""
    permitted = get_permitted_dbs(claims)
    return DatabasesResponse(databases=permitted)


@router.get("/schema/{customer_db}", response_model=SchemaResponse)
async def get_schema(
    customer_db: str,
    claims: dict[str, Any] = Depends(_get_claims),
) -> SchemaResponse:
    """Return the schema description for a customer database (for use by the chat UI)."""
    if not check_rbac(claims, customer_db):
        raise HTTPException(
            status_code=403,
            detail=f"Access to database '{customer_db}' is not permitted for this user.",
        )

    tables = []
    for table_name, meta in SCHEMA_CONTEXT.items():
        tables.append({
            "table": table_name,
            "description": meta["description"],
            "columns": [
                {"name": col, "description": desc}
                for col, desc in meta["columns"].items()
            ],
        })

    return SchemaResponse(tables=tables)
