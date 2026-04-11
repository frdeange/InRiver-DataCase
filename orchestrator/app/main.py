"""FastAPI application for the InRiver DataCase orchestrator."""

from __future__ import annotations

import time
from typing import Any

import structlog
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from app.pipeline import MockPipeline, get_pipeline

logger = structlog.get_logger()

app = FastAPI(
    title="InRiver DataCase Orchestrator",
    description="AI-powered NL query interface for PIM databases",
    version="0.1.0",
)


# -- Request / Response models -----------------------------------------------


class QueryRequest(BaseModel):
    question: str
    database: str
    schema_: str = ""
    user_email: str = ""

    model_config = {"populate_by_name": True, "json_schema_extra": {"examples": [{"question": "Show all products", "database": "db-acme", "schema": "", "user_email": "user@example.com"}]}}

    def __init__(self, **data: Any) -> None:
        # Accept "schema" from JSON payload but map to schema_
        if "schema" in data and "schema_" not in data:
            data["schema_"] = data.pop("schema")
        super().__init__(**data)


class QueryResponse(BaseModel):
    answer: str
    sql: str
    database: str
    execution_time_ms: float


# -- Routes -------------------------------------------------------------------


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "healthy"}


@app.post("/process", response_model=QueryResponse)
async def process_query(request: QueryRequest) -> QueryResponse:
    logger.info(
        "processing_query",
        question=request.question,
        database=request.database,
        user_email=request.user_email,
    )

    pipeline = get_pipeline()
    result = await pipeline.run(
        question=request.question,
        database=request.database,
        schema=request.schema_,
        user_email=request.user_email,
    )

    if result.error and not result.safe:
        raise HTTPException(status_code=400, detail=result.error)

    return QueryResponse(
        answer=result.answer,
        sql=result.sql,
        database=result.database,
        execution_time_ms=round(result.execution_time_ms, 2),
    )
