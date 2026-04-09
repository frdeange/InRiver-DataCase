# InRiver DataCase — Backend

FastAPI backend for the InRiver DataCase proof-of-concept. Translates natural-language questions into T-SQL SELECT queries, executes them against Azure SQL PIM databases, and returns results to the frontend.

## Prerequisites

- Python 3.12+
- [Microsoft ODBC Driver 18 for SQL Server](https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server)
- Azure OpenAI / AI Foundry deployment (GPT-4.1)
- Azure Entra ID App Registration (for token validation)
- Three Azure SQL databases with `database/schema.sql` applied and seed data loaded

## Local Setup

```bash
# 1. Navigate to backend
cd backend

# 2. Create a virtual environment
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure environment variables
cp .env.example .env
# Edit .env and fill in real values

# 5. Run the API
uvicorn app.main:app --reload --port 8000
```

API docs: `http://localhost:8000/docs`

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `AZURE_TENANT_ID` | ✅ | Entra ID tenant ID |
| `AZURE_CLIENT_ID` | ✅ | App Registration client ID (JWT audience) |
| `AZURE_OPENAI_ENDPOINT` | ✅ | Azure OpenAI / AI Foundry endpoint URL |
| `AZURE_OPENAI_KEY` | ✅ | Azure OpenAI API key |
| `AZURE_OPENAI_DEPLOYMENT` | ✅ | Deployment name (default: `gpt-4.1`) |
| `DB_ACME_CONNECTION_STRING` | ✅ | SQLAlchemy connection string for ACME DB |
| `DB_NOVA_CONNECTION_STRING` | ✅ | SQLAlchemy connection string for Nova DB |
| `DB_APEX_CONNECTION_STRING` | ✅ | SQLAlchemy connection string for Apex DB |
| `APPINSIGHTS_CONNECTION_STRING` | ⬜ | Application Insights telemetry |
| `ALLOWED_ORIGINS` | ⬜ | Comma-separated CORS origins (default: `http://localhost:3000`) |
| `MAX_QUERY_LENGTH` | ⬜ | Max chars in user question (default: `2000`) |
| `QUERY_TIMEOUT_SECONDS` | ⬜ | DB query timeout (default: `30`) |

## Database Connection String Format

```
mssql+pyodbc://<user>:<password>@<server>.database.windows.net/<database>?driver=ODBC+Driver+18+for+SQL+Server
```

The read-only DB user should have `SELECT` permission only — no DDL or DML.

## API Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Liveness probe |
| `POST` | `/api/query` | Natural-language → SQL → results |
| `GET` | `/api/databases` | List permitted databases for authenticated user |
| `GET` | `/api/schema/{customer_db}` | Schema description for a database |

### POST `/api/query`

```json
// Request
{ "question": "Show me all active products in the Electronics category", "customer_db": "acme" }

// Response
{ "sql": "SELECT TOP 100 ...", "explanation": "...", "results": [...], "row_count": 12 }
```

All requests require `Authorization: Bearer <token>` (Entra ID JWT).

## Docker

```bash
docker build -t inriver-datacase-backend .
docker run -p 8000:8000 --env-file .env inriver-datacase-backend
```

## Project Structure

```
backend/
├── app/
│   ├── main.py              # FastAPI app factory, CORS, lifespan
│   ├── config.py            # Pydantic Settings (env vars)
│   ├── agents/
│   │   ├── sql_agent.py     # AI agent: generate → validate → execute loop
│   │   └── schema_context.py # Static PIM schema description for prompt injection
│   ├── api/
│   │   ├── routes.py        # POST /api/query, GET /api/databases, GET /api/schema/{db}
│   │   └── stubs.py         # Fallback stubs for auth/guardrail modules (Linus owns these)
│   ├── auth/
│   │   └── validator.py     # Entra ID JWT validation (JWKS, issuer, audience)
│   ├── db/
│   │   └── connections.py   # SQLAlchemy engine factory + execute_query
│   └── guardrails/          # Populated by Linus (RBAC, SQL validator, prompt safety)
├── requirements.txt
├── Dockerfile
└── .env.example
```

## Security Notes

- JWT validated on every request (signature + expiry + audience + issuer).
- SQL guardrails run on every AI-generated query before execution (Linus's AST validator supersedes stub).
- Database connections use a read-only SQL login.
- No query result data is logged — only metadata (row count, latency).
