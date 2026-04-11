# InRiver DataCase

AI-powered natural-language query interface for InRiver PIM databases. Users ask questions in plain language; the system generates SQL, validates it, executes it against the user's authorized database, and returns a formatted answer.

## Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│   Frontend   │────▶│   Backend    │────▶│   Orchestrator   │
│  React SPA   │     │   FastAPI    │     │   FastAPI + MAF  │
│  :5173/:3000 │     │    :8000     │     │      :8001       │
└──────────────┘     └──────┬───────┘     └────────┬─────────┘
                            │                      │
                      ┌─────▼─────┐         ┌──────▼──────────┐
                      │  Azure SQL │         │ Azure AI Foundry│
                      │ db-users   │         │  3 PromptAgents │
                      │ db-acme    │         │  + FunctionTools │
                      │ db-nova    │         └─────────────────┘
                      │ db-apex    │
                      └────────────┘
```

| Service | Stack | Port |
|---------|-------|------|
| Frontend | React 19 + TypeScript + Vite + Tailwind CSS v4 + Zustand | 5173 (dev) / 3000 (docker) |
| Backend | Python 3.13 + FastAPI + bcrypt + JWT + sqlglot + structlog | 8000 |
| Orchestrator | Python 3.13 + FastAPI + Microsoft Agent Framework + FoundryAgent | 8001 |

### Tenant Isolation

Users are mapped to databases by their email domain. The backend resolves this server-side — the frontend never selects a database.

| Domain | Database(s) |
|--------|------------|
| acme.com | db-acme |
| nova.com | db-nova |
| apex.com | db-apex |
| inriver.com | db-acme, db-nova, db-apex (admin) |

### AI Agent Pipeline

```
User Question → HandoffBuilder Workflow
  1. SafetyAgent      → screens for injection/harmful input
  2. SQLGeneratorAgent → generates T-SQL (with FunctionTools: get_schema, validate_sql, execute_sql)
  3. FormatterAgent   → converts raw results to natural language
```

## Quick Start

### Prerequisites

- Python 3.13+
- Node.js 24+
- Azure CLI authenticated (`az login`)

### Local Development

```bash
# Backend
cd backend
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --port 8000

# Orchestrator
cd orchestrator
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --port 8001

# Frontend
cd frontend
npm install
cp .env.example .env
npm run dev
```

### Docker Compose

```bash
docker compose up --build
# Frontend: http://localhost:3000
# Backend:  http://localhost:8000
# Orchestrator: http://localhost:8001
```

### Azure Deployment

```bash
./scripts/deploy.sh -g RG-InRiver
```

## Test Users

| Email | Password | Database |
|-------|----------|----------|
| `alice@acme.com` | `AcmeUser1!` | db-acme |
| `bob@nova.com` | `NovaUser1!` | db-nova |
| `carol@apex.com` | `ApexUser1!` | db-apex |
| `admin@inriver.com` | `AdminUser1!` | ALL |

## Running Tests

```bash
# Backend (25 tests)
cd backend && pytest

# Orchestrator (8 tests)
cd orchestrator && pytest

# Frontend (12 tests)
cd frontend && npx vitest run

# Single test file
cd backend && pytest tests/test_auth.py
cd backend && pytest -k "test_login_success"
```

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/v1/auth/login` | No | Login with email/password → JWT tokens |
| POST | `/api/v1/auth/refresh` | No | Refresh access token |
| GET | `/api/v1/databases` | Yes | List user's authorized databases |
| POST | `/api/v1/query` | Yes | Submit natural-language query |
| GET | `/health` | No | Health check |
| GET | `/ready` | No | Readiness check |

## Infrastructure

- **Azure SQL Server**: `inriver-dev-sql.database.windows.net`
- **Databases**: db-users, db-acme, db-nova, db-apex
- **Azure AI Foundry**: 3 PromptAgents (inriver-safety, inriver-sql-generator, inriver-response-formatter)
- **Azure Container Registry**: `inriverdevacr.azurecr.io`
- **Container Apps**: inriver-dev-api, inriver-dev-frontend, inriver-dev-orchestrator
- **IaC**: Bicep modules in `infra/`

## Project Structure

```
backend/          FastAPI backend (auth, API, SQL security, audit)
orchestrator/     FastAPI orchestrator (Agent Framework pipeline)
frontend/         React SPA (login, chat UI)
database/         SQL schemas and seed data
scripts/          Deployment and provisioning scripts
infra/            Bicep IaC modules
docs/design/      Architecture documentation
```
