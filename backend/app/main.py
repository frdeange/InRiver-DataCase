from __future__ import annotations

import logging

from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.api.routes import router

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan: load config and pre-warm DB connection pools on startup."""
    settings = get_settings()
    logger.info("Starting InRiver DataCase API")
    logger.info("OpenAI deployment: %s", settings.azure_openai_deployment)

    # Pre-warm engines so the first request doesn't pay the connection cost.
    from app.db.connections import get_engine, VALID_CUSTOMER_DBS

    for db_key in VALID_CUSTOMER_DBS:
        try:
            get_engine(db_key)
            logger.info("DB engine ready for '%s'", db_key)
        except Exception as exc:
            logger.warning("Could not initialise engine for '%s': %s", db_key, exc)

    yield

    logger.info("Shutting down InRiver DataCase API")


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title="InRiver DataCase API",
        description=(
            "AI-powered SQL query agent for InRiver PIM databases. "
            "Authenticated users can ask natural-language questions about product data."
        ),
        version="0.1.0",
        docs_url="/docs",
        redoc_url="/redoc",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(router)

    @app.get("/health", tags=["health"])
    async def health_check() -> dict:
        """Simple liveness probe."""
        return {"status": "ok", "service": "inriver-datacase-api"}

    return app


app = create_app()
