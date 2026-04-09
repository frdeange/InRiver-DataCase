# InRiver DataCase

AI-powered natural-language query interface for InRiver PIM databases. Ask questions in plain English and get SQL-backed answers — secured by Azure Entra ID, RBAC, and multi-layer guardrails.

## Architecture

```
┌─────────────┐     HTTPS      ┌──────────────────────────────┐      Azure SQL
│  React SPA  │ ───────────── ▶│  FastAPI Backend              │ ──────────────▶  db-acme
│  (MSAL Auth)│  Bearer JWT    │                                │                  db-nova
│  Tailwind   │◀──────────────│  ┌──────────┐ ┌────────────┐  │                  db-apex
└─────────────┘   JSON         │  │ Prompt   │ │ SQL        │  │
   :3000                       │  │ Safety   │ │ Validator  │  │
                               │  └──────────┘ └────────────┘  │
                               │  ┌──────────┐ ┌────────────┐  │
                               │  │ RBAC     │ │ AI SQL Gen │  │
                               │  │ (Entra)  │ │ (Azure AI) │  │
                               │  └──────────┘ └────────────┘  │
                               │  ┌──────────────────────────┐ │
                               │  │ Audit Logger (NDJSON)    │ │
                               │  └──────────────────────────┘ │
                               └──────────────────────────────┘
                                   :8000
```

## Quick Start (Local Development)

### With Docker Compose

```bash
# Copy env files
cp backend/.env.example backend/.env
# Edit backend/.env with your Azure credentials

docker compose up --build
# Frontend: http://localhost:3000
# Backend:  http://localhost:8000/health
```

### Without Docker

```bash
# Backend
cd backend
pip install -r requirements.txt
cp .env.example .env  # Edit with your credentials
uvicorn app.main:app --reload --port 8000

# Frontend (separate terminal)
cd frontend
npm install
npm run dev
# Open http://localhost:5173
```

## Security Features

| Layer | Module | Protection |
|-------|--------|------------|
| **Prompt Safety** | `app/guardrails/prompt_safety.py` | Detects injection attempts, data exfiltration, and cross-tenant pivots |
| **SQL Validation** | `app/guardrails/sql_validator.py` | AST-level validation — only single SELECT statements allowed |
| **RBAC** | `app/auth/rbac.py` | Per-user database permissions with deny-by-default |
| **JWT Auth** | `app/auth/validator.py` | Entra ID token validation with JWKS |
| **Audit Logging** | `app/observability/audit_logger.py` | Every query attempt logged (allowed and rejected) |

## Folder Structure

```
InRiver-DataCase/
├── backend/              # Python FastAPI API
│   ├── app/
│   │   ├── agents/       # AI SQL generation + schema context
│   │   ├── api/          # Routes + adapter stubs
│   │   ├── auth/         # JWT validation + RBAC
│   │   ├── db/           # SQLAlchemy connection management
│   │   ├── guardrails/   # Prompt safety + SQL validation
│   │   └── observability/# Audit logging
│   ├── tests/            # 46 security tests
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/             # React + TypeScript SPA
│   ├── src/
│   │   ├── api/          # Axios client + query functions
│   │   ├── auth/         # MSAL configuration + hooks
│   │   └── components/   # Chat UI, database selector, results
│   ├── Dockerfile
│   └── nginx.conf
├── database/             # T-SQL schema + seed data
│   ├── schema.sql
│   └── seed-customer-*.sql
├── infra/                # Azure Bicep IaC
│   ├── main.bicep
│   └── modules/
└── docker-compose.yml
```

## Component READMEs

- [Backend README](backend/README.md)
- [Frontend README](frontend/README.md)

## Running Tests

```bash
cd backend
python -m pytest tests/ -v
# 46 tests covering SQL validation, prompt safety, and RBAC
```

## Environment Variables

See [`backend/.env.example`](backend/.env.example) for the full list of required configuration.

## License

Private — InRiver demonstration project.
