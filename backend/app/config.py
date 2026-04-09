from __future__ import annotations

from functools import lru_cache
from typing import Any

from pydantic import Field, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # --- Entra ID ---
    azure_tenant_id: str = Field(..., description="Azure Entra ID tenant ID")
    azure_client_id: str = Field(..., description="App Registration client ID (audience)")

    # --- Azure OpenAI ---
    azure_openai_endpoint: str = Field(..., description="Azure OpenAI / AI Foundry endpoint URL")
    azure_openai_key: str = Field(..., description="Azure OpenAI API key")
    azure_openai_deployment: str = Field(default="gpt-4.1", description="Deployment name")

    # --- Database connection strings ---
    db_acme_connection_string: str = Field(..., description="SQLAlchemy connection string for ACME DB")
    db_nova_connection_string: str = Field(..., description="SQLAlchemy connection string for Nova DB")
    db_apex_connection_string: str = Field(..., description="SQLAlchemy connection string for Apex DB")

    # --- Optional telemetry ---
    appinsights_connection_string: str | None = Field(
        default=None, description="Application Insights connection string"
    )

    # --- CORS ---
    allowed_origins: str = Field(
        default="http://localhost:3000",
        description="Comma-separated list of allowed CORS origins",
    )

    # --- Query safety limits ---
    max_query_length: int = Field(default=2000, description="Maximum allowed question length in characters")
    query_timeout_seconds: int = Field(default=30, description="SQL query execution timeout in seconds")

    @computed_field  # type: ignore[prop-decorator]
    @property
    def allowed_origins_list(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",") if o.strip()]


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
