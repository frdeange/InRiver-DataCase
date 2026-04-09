from __future__ import annotations

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # --- Azure AI Foundry ---
    ms_foundry_project_endpoint: str = Field(default="", description="Azure AI Foundry project endpoint URL")
    mf_foundry_deployment_name: str = Field(default="gpt-5.4", description="Model deployment name")

    # --- Azure SQL ---
    azure_sql_server: str = Field(default="", description="Azure SQL FQDN")
    azure_sql_database_prefix: str = Field(default="db", description="Database name prefix, e.g. 'db' -> 'db-acme'")
    azure_sql_user: str = Field(default="", description="SQL login username")
    azure_sql_password: str = Field(default="", description="SQL login password")

    # --- Dev mode ---
    use_local_sqlite: bool = Field(default=True, description="Use local SQLite files instead of Azure SQL")

    # --- CORS ---
    allowed_origins: list[str] = Field(default=["*"], description="Allowed CORS origins")

    # --- Entra ID token validation ---
    jwt_tenant_id: str = Field(default="", description="Azure Entra ID tenant ID for JWT validation")
    jwt_audience: str = Field(default="", description="App Registration client ID (JWT audience)")

    # --- Optional telemetry ---
    appinsights_connection_string: str = Field(default="", description="Application Insights connection string")

    # --- Query safety limits ---
    query_timeout_seconds: int = Field(default=30, description="SQL query execution timeout in seconds")


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
