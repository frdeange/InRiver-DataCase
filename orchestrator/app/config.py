"""Application settings loaded from environment variables."""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Configuration for the orchestrator service."""

    AI_PROJECT_ENDPOINT: str = (
        "https://inriver-dev-ais.services.ai.azure.com/api/projects/inriver-dev-project"
    )
    MODEL_DEPLOYMENT: str = "gpt-5.4"
    SQL_SERVER: str = "inriver-dev-sql.database.windows.net"
    USE_MOCK_DB: bool = False
    USE_REAL_AGENTS: bool = False
    MCP_TOOLS_URL: str = "http://localhost:8002/mcp"
    BACKEND_URL: str = "http://localhost:8000"
    AZURE_CLIENT_ID: str = ""

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
