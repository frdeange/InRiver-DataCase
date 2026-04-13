"""Entry point for the MCP Tools server."""

import os

import uvicorn

# ── Azure Monitor / OpenTelemetry ───────────────────────────
if os.environ.get("APPLICATIONINSIGHTS_CONNECTION_STRING"):
    try:
        from azure.monitor.opentelemetry import configure_azure_monitor

        configure_azure_monitor()
    except ImportError:
        pass

from app.server import mcp

# Create the Starlette ASGI app for Streamable HTTP transport
app = mcp.http_app()

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8002)
