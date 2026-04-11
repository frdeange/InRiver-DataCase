# Copilot Instructions — InRiver DataCase

## Project Overview

InRiver DataCase is an AI-powered natural-language query interface for InRiver PIM databases. Users authenticate, and the system uses AI agents (Azure AI Foundry) to translate questions into SQL, validate, execute, and format results. Strict tenant isolation ensures users only access databases mapped to their email domain.

## Architecture

Three containerized services deployed as Azure Container Apps:

- **Backend** (`backend/`) — Python 3.13 + FastAPI. Handles auth, authorization, domain-to-database resolution, and proxies queries to the orchestrator. All routes under `/api/v1/`.
- **Orchestrator** (`orchestrator/`) — Python 3.13 + FastAPI. Runs the AI agent pipeline using Microsoft Agent Framework `HandoffBuilder` → `Workflow`. Agents are persistent PromptAgents registered in Azure AI Foundry, consumed via `FoundryAgent`. Tools decorated with `@tool` from `agent_framework`.
- **Frontend** (`frontend/`) — React 19 + TypeScript + Vite + Tailwind CSS + Zustand. Served by Nginx in production. No MSAL — custom login form with JWT auth.

Supporting infrastructure:

- **Azure SQL** — 4 databases on one server: `db-acme`, `db-nova`, `db-apex` (tenant PIM data), `db-users` (auth + domain mapping).
- **IaC** — Bicep modules in `infra/`, orchestrated by `infra/main.bicep`. Supports reuse of existing resources via `existing*Id` parameters.
- **Deployment** — `scripts/deploy.sh` runs the full pipeline: preflight → Bicep → agent provisioning → Docker build/push → seed databases → grant SQL access.
- **Container Registry** — `inriverdevacr.azurecr.io`. Base images imported under `base/` (python, node, nginx). All Dockerfiles use ACR base images, not Docker Hub.

## Build & Run Commands

```bash
# Local dev (Docker Compose) — backend :8000, frontend :3000
docker compose up --build

# Backend
cd backend && pip install -r requirements.txt
cd backend && uvicorn app.main:app --reload --port 8000
cd backend && pytest                     # full test suite
cd backend && pytest tests/test_auth.py  # single test file
cd backend && pytest -k "test_login"     # single test by name

# Orchestrator
cd orchestrator && pip install -r requirements.txt
cd orchestrator && pytest

# Frontend
cd frontend && npm install
cd frontend && npm run dev               # Vite dev server :5173
cd frontend && npm run build             # production build
cd frontend && npx vitest                # full test suite
cd frontend && npx vitest run src/auth/  # tests in a directory

# Infrastructure
az bicep build --file infra/main.bicep   # validate Bicep
./scripts/deploy.sh -g RG-InRiver       # full deployment
./scripts/deploy.sh -g RG-InRiver -y --skip-docker --skip-seed  # infra only
```

## Key Conventions

### Authentication & Authorization

- Custom email/password auth with bcrypt + JWT (HS256). **Do NOT use Microsoft Entra ID / MSAL** for user authentication.
- Access token TTL: 15 min, refresh token TTL: 7 days. Tokens stored in memory (React state/context), never localStorage.
- Database access is determined server-side from the user's email domain via the `domain_database_map` table. The frontend never selects a database.

### SQL Security

- Only `SELECT` queries are allowed. Validation uses AST-level parsing with `sqlglot` — not regex.
- The Data Access Layer is the sole component that executes SQL.
- All query attempts (approved and rejected) are audit-logged using structlog in NDJSON format.

### AI Agents

- 3 PromptAgents registered in Azure AI Foundry: `inriver-safety`, `inriver-sql-generator`, `inriver-response-formatter`.
- Created via `azure-ai-projects` SDK (`AIProjectClient.agents.create_version()`). Provisioning script: `scripts/setup-agents.py` (idempotent).
- Consumed using `FoundryAgent` from `agent-framework-foundry`.
- Orchestration uses `HandoffBuilder` from `agent_framework.orchestrations` — builds a `Workflow`, invoked with `await workflow.run(message)`. Do NOT implement manual if/else pipelines.
- FunctionTools decorated with `@tool` from `agent_framework`: `validate_sql`, `execute_sql`, `get_schema`.
- Model deployment: `gpt-5.4`.

### Code Style

- All code in English (variables, functions, comments, docstrings).
- Python: formatted with Black, type hints expected.
- TypeScript/JS: formatted with Prettier, ESLint for linting.
- Python testing: pytest. Frontend testing: vitest.
- Every feature must include tests and documentation.

### Environment

- DevContainer-based development (Python 3.13 base image with Node.js, Azure CLI, Docker-in-Docker, GitHub CLI).
- Install dependencies directly in the DevContainer — **do not use venv**.
- ODBC Driver 18 and sqlcmd are available for SQL Server access.
- Before any Azure operation, verify login with `az account show`.

### Database Schema (PIM)

The tenant databases (`db-acme`, `db-nova`, `db-apex`) share a common PIM schema defined in `database/schema.sql`: `Categories` (hierarchical), `Products`, `Attributes`, `ProductAttributes` (junction), `Customers`, `Orders`. Key constraints: Products have a status enum (`Draft`/`Review`/`Approved`/`Published`/`Archived`), Orders have a computed `TotalAmount` column.

### Infrastructure

- All Azure resources in resource group `RG-InRiver`, region `swedencentral`.
- Bicep modules: `acr`, `ai-foundry`, `container-apps`, `identity`, `keyvault`, `monitoring`, `sql`, `storage`.
- Extend existing Bicep and scripts — do not replace them.
