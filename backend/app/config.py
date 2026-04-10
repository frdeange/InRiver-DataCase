from __future__ import annotations

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
    }

    # Azure AI Foundry
    azure_ai_project_endpoint: str = ""
    azure_ai_model_deployment_name: str = "gpt-5.2"

    # Azure SQL per-tenant connections
    sql_conn_acme: str = ""
    sql_conn_nova: str = ""
    sql_conn_apex: str = ""

    # Entra ID
    azure_tenant_id: str = ""
    azure_client_id: str = ""

    # Observability
    log_level: str = "INFO"
    audit_log_path: str = "./audit_logs"
    applicationinsights_connection_string: str = ""

    @property
    def tenant_connections(self) -> dict[str, str]:
        return {
            "acme": self.sql_conn_acme,
            "nova": self.sql_conn_nova,
            "apex": self.sql_conn_apex,
        }


settings = Settings()
