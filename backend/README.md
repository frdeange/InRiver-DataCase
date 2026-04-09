# backend/

Python FastAPI backend for the InRiver Agentic SQL PoC.

## Structure

```
backend/
├── app/
│   ├── main.py              # FastAPI app entry point, middleware registration
│   ├── config.py            # Settings (loaded from env / Key Vault)
│   ├── auth/                # Entra ID JWT validation + RBAC resolver
│   │   ├── jwt_validator.py # Validates Bearer tokens against Entra ID JWKS
│   │   └── rbac.py          # Maps Entra ID group OIDs → permitted databases
│   ├── agents/              # Azure OpenAI SQL generation agent
│   │   ├── sql_agent.py     # Main agent: prompt construction + GPT-4.1 call + retry loop
│   │   └── schema_loader.py # Loads DB schema (CREATE TABLE DDL) for prompt injection
│   ├── guardrails/          # SQL AST validation (sqlparse-based)
│   │   ├── validator.py     # AST walker: allowlist SELECT, block DDL/DML/DCL
│   │   └── rules.py         # Rule definitions (blocked keywords, system tables, etc.)
│   ├── db/                  # Azure SQL connectivity
│   │   ├── connections.py   # Connection pool per database (connection strings from Key Vault)
│   │   └── executor.py      # Executes validated SQL, enforces row cap + timeout
│   └── api/                 # FastAPI routers
│       ├── query.py         # POST /api/query — main query endpoint
│       ├── databases.py     # GET /api/databases — user's permitted DB list
│       └── health.py        # GET /health — liveness probe for Container Apps
├── requirements.txt         # Python dependencies
└── Dockerfile               # Multi-stage build: builder + slim runtime image
```

## Local Development

```bash
cd backend
pip install -r requirements.txt
cp ../.env.example .env       # Fill in local values
uvicorn app.main:app --reload --port 8000
```

API docs available at http://localhost:8000/docs (OpenAPI/Swagger UI).

## Environment Variables

| Variable | Source | Description |
|----------|--------|-------------|
| `AZURE_TENANT_ID` | .env / Key Vault | Entra ID tenant for JWT validation |
| `AZURE_CLIENT_ID` | .env / Key Vault | App Registration client ID (audience claim) |
| `AZURE_OPENAI_ENDPOINT` | Key Vault | AI Foundry endpoint |
| `AZURE_OPENAI_DEPLOYMENT` | .env | GPT-4.1 deployment name |
| `DB_ALPHA_CONNECTION` | Key Vault | Azure SQL connection string for pim-alpha |
| `DB_BETA_CONNECTION` | Key Vault | Azure SQL connection string for pim-beta |
| `DB_GAMMA_CONNECTION` | Key Vault | Azure SQL connection string for pim-gamma |
| `APPINSIGHTS_CONNECTION_STRING` | Key Vault | App Insights telemetry |
| `RBAC_CONFIG` | .env / Key Vault | JSON mapping group OIDs → database names |

## Security Notes

- JWT is validated on every request (signature + expiry + audience + issuer).
- SQL guardrails run on every AI-generated query before execution.
- Database connections use read-only SQL logins (`pim_reader`).
- No query result data is logged (only metadata: row count, latency, user OID).
