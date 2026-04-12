from typing import Any

import httpx
import structlog
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.auth.dependencies import get_current_user
from app.auth.domain_resolver import DomainResolver
from app.auth.models import UserInfo
from app.config import settings
from app.db.schema_cache import SchemaCache
from app.guardrails.sql_validator import SQLValidator
from app.observability.audit_logger import AuditLogger

router = APIRouter(tags=["query"])
logger = structlog.get_logger()
domain_resolver = DomainResolver()
schema_cache = SchemaCache()
sql_validator = SQLValidator()
audit_logger = AuditLogger()


class QueryRequest(BaseModel):
    question: str
    database: str | None = None


class QueryResponse(BaseModel):
    answer: str | None = None
    sql: str | None = None
    database: str
    execution_time_ms: float = 0
    columns: list[str] | None = None
    rows: list[dict[str, Any]] | None = None
    error: str | None = None


@router.post("/query", response_model=QueryResponse)
async def execute_query(
    request: QueryRequest,
    current_user: UserInfo = Depends(get_current_user),
) -> QueryResponse:
    authorized_dbs = domain_resolver.resolve(current_user.domain)

    if request.database:
        if request.database not in authorized_dbs:
            raise HTTPException(
                status_code=403,
                detail=f"Access denied to database '{request.database}'",
            )
        target_db = request.database
    elif len(authorized_dbs) == 1:
        target_db = authorized_dbs[0]
    else:
        raise HTTPException(
            status_code=400,
            detail="Multiple databases available. Please specify a database.",
        )

    schema = schema_cache.get_schema(target_db)

    # Call the orchestrator service
    try:
        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                f"{settings.ORCHESTRATOR_URL}/process",
                json={
                    "question": request.question,
                    "database": target_db,
                    "schema": schema,
                },
            )
            response.raise_for_status()
            data = response.json()

            # Validate SQL if returned
            if data.get("sql"):
                is_valid, reason = sql_validator.validate(data["sql"])
                audit_logger.log_query_attempt(
                    user_email=current_user.email,
                    database=target_db,
                    query=data["sql"],
                    approved=is_valid,
                    reason=reason,
                )
                if not is_valid:
                    return QueryResponse(
                        database=target_db,
                        error=f"Query rejected: {reason}",
                        answer=f"Query rejected: {reason}",
                    )

            # Convert array rows to dicts if columns are present
            columns = data.get("columns")
            raw_rows = data.get("rows") or data.get("results")
            rows = raw_rows
            if columns and raw_rows and isinstance(raw_rows[0], list):
                rows = [dict(zip(columns, row)) for row in raw_rows]

            return QueryResponse(
                database=target_db,
                sql=data.get("sql"),
                columns=columns,
                rows=rows,
                answer=data.get("answer", ""),
                execution_time_ms=data.get("execution_time_ms", 0),
            )

    except httpx.HTTPError:
        logger.warning("orchestrator_unavailable", url=settings.ORCHESTRATOR_URL)
        # Mock fallback
        mock_rows = [
            {"ProductName": "Widget Pro", "ListPrice": 29.99},
            {"ProductName": "Gadget Elite", "ListPrice": 49.99},
            {"ProductName": "Sensor Max", "ListPrice": 19.99},
        ]
        return QueryResponse(
            database=target_db,
            sql="SELECT TOP 10 ProductName, ListPrice FROM Products WHERE IsActive = 1",
            columns=["ProductName", "ListPrice"],
            rows=mock_rows,
            answer=(
                "Here are the top products from your catalog. "
                "(Mock response — orchestrator is not available)"
            ),
            execution_time_ms=0,
        )
