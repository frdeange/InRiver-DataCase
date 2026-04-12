"""Entry point for the MCP Tools server."""

import uvicorn

from app.server import mcp

# Create the Starlette ASGI app for Streamable HTTP transport
app = mcp.http_app()

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8002)
