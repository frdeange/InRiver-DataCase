# Backend — InRiver DataCase API

FastAPI service handling authentication, authorization, query processing, and SQL security.

## Stack

Python 3.13 · FastAPI · Pydantic · bcrypt · python-jose (JWT) · sqlglot · structlog · aioodbc

## Run

```bash
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --port 8000
```

## Test

```bash
pytest                           # full suite (25 tests)
pytest tests/test_auth.py        # single file
pytest -k "test_login_success"   # single test by name
```

## API Routes

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/v1/auth/login` | No | `{email, password}` → `{access_token, refresh_token}` |
| POST | `/api/v1/auth/refresh` | No | `{refresh_token}` → `{access_token}` |
| GET | `/api/v1/databases` | Bearer | Returns user's authorized databases |
| POST | `/api/v1/query` | Bearer | `{question}` → `{answer, sql, database}` |
| GET | `/health` | No | `{"status": "healthy"}` |
| GET | `/ready` | No | `{"status": "ready"}` |

## Architecture

```
app/
  main.py              FastAPI app, CORS, structlog
  config.py            Settings (pydantic-settings, .env)
  auth/
    models.py          Pydantic models (LoginRequest, TokenResponse, UserInfo)
    service.py         bcrypt hashing, JWT creation/verification (HS256)
    dependencies.py    get_current_user FastAPI dependency
    domain_resolver.py Email domain → database mapping
  api/v1/
    auth.py            Login + refresh routes
    query.py           Query submission (calls orchestrator)
    databases.py       Authorized database listing
  db/
    connection.py      Tenant-scoped DB connections (mock + Azure SQL)
    user_db.py         User lookup operations
    schema_cache.py    PIM schema caching
  guardrails/
    sql_validator.py   sqlglot AST validation (SELECT-only)
  observability/
    audit_logger.py    NDJSON audit logging (all query attempts)
```

## Key Design Decisions

- **JWT HS256**: Access tokens (15min), refresh tokens (7 days). Claims: `sub`, `email`, `domain`, `exp`, `iat`.
- **SQL Validation**: AST-level parsing with sqlglot — not regex. Only `SELECT` allowed.
- **Tenant Isolation**: Database resolved server-side from JWT email domain. Frontend cannot choose.
- **Mock Mode**: `USE_MOCK_DB=true` enables local dev without Azure SQL.
- **Audit Logging**: Every query attempt (approved + rejected) logged in NDJSON via structlog.
