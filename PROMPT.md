You are an expert full-stack AI engineer tasked with building a complete PoC for "InRiver DataCase" — an AI-powered natural-language query interface for InRiver PIM databases. This project must be built from the existing repository skeleton on the `dev` branch.

---

## 🎯 PROJECT OBJECTIVE

Build a secure web application where authenticated users can ask natural-language questions through a chat interface, and the system uses AI agents hosted in Azure AI Foundry to generate, validate, and execute SQL queries against the user's authorized Azure SQL database(s). The system must enforce strict tenant isolation: a user can ONLY access databases explicitly mapped to their email domain.

---

## 📁 EXISTING REPOSITORY STATE

The `dev` branch contains:
- `database/` — SQL schema (`schema.sql`) and seed data for 3 tenant databases (`seed-acme.sql`, `seed-nova.sql`, `seed-apex.sql`)
- `docs/design/` — Architecture documents (secure SQL access strategy, agent architecture review)
- `infra/` — Bicep IaC modules (ACR, AI Foundry, Container Apps, Identity, Key Vault, Monitoring, SQL, Storage) + `main.bicep` orchestrator
- `scripts/` — Deployment scripts (`deploy.sh`, `preflight.sh`, `teardown.sh`, `seed-databases.sh`, `grant-sql-access.sh`, `setup-entra-apps.sh`)
- `.devcontainer/` — DevContainer configuration
- `.github/AGENTS.md` — Project guidelines
- `docker-compose.yml`, `.env`, `.gitignore`, `requirements.txt`

**What does NOT exist yet:** backend application, frontend application, agents, orchestration, tests.

---

## 🏗️ ARCHITECTURE REQUIREMENTS

### 1. Authentication — Custom User Database (NOT Entra ID)

- **Do NOT use Microsoft Entra ID / MSAL** for user authentication. Use a custom authentication system.
- Create a `users` table in a dedicated Azure SQL database (`db-users` on the same SQL server as the tenant databases).
- The `users` table must store: `id`, `email`, `password_hash`, `full_name`, `is_active`, `created_at`.
- Passwords must be hashed with `bcrypt` (never stored in plain text).
- Password requirements: minimum 8 characters, at least 1 uppercase, 1 lowercase, 1 number.
- The backend must expose `/api/v1/auth/login` (returns JWT access + refresh tokens) and `/api/v1/auth/refresh` (renews access token).
- JWT tokens must be signed with a server-side secret (HS256), include `sub` (user_id), `email`, `domain` (extracted from email), `exp`, `iat`.
- Access token TTL: 15 minutes. Refresh token TTL: 7 days.
- The frontend must present a login form (email + password), store tokens in memory (NOT localStorage), and attach the access token as `Authorization: Bearer` header on every API call.
- Create test users for the PoC seed:
  - `alice@acme.com` / `AcmeUser1!` → maps to `db-acme`
  - `bob@nova.com` / `NovaUser1!` → maps to `db-nova`
  - `carol@apex.com` / `ApexUser1!` → maps to `db-apex`
  - `admin@inriver.com` / `AdminUser1!` → maps to ALL databases (admin override)

### 2. Authorization — Domain-Based Database Access

- Create a `domain_database_map` table in `db-users`: `id`, `email_domain`, `database_name`, `is_active`.
- Seed it with: `acme.com` → `db-acme`, `nova.com` → `db-nova`, `apex.com` → `db-apex`, `inriver.com` → ALL (admin).
- The backend must extract the email domain from the authenticated JWT and resolve which database(s) the user can access.
- The frontend must NOT allow the user to select or specify a database. The database is **automatically determined** server-side from the user's domain.
- If a user's domain maps to exactly one database, queries go there automatically.
- If a user's domain maps to multiple databases (admin/future case), the backend should expose `GET /api/v1/databases` listing only the authorized ones, and the UI may show a read-only indicator.
- **Under no circumstance** can a user query a database not mapped to their domain. This must be enforced server-side — never trust the frontend.

### 3. AI Agents — PromptAgents Hosted in Azure AI Foundry

- All AI agents must be **persistent PromptAgents registered in the Azure AI Foundry project**.
- Agents are created using `azure-ai-projects` SDK (`AIProjectClient.agents.create_agent()`).
- Agents are consumed using `agent-framework-foundry` SDK (`FoundryAgent` class).
- Each agent must have well-defined instructions, a model deployment (`gpt-5.4`), and optionally client-side `FunctionTool`s.
- Use the **Foundry v2 API** (`api-version 2025-05-01` or later). Verify compatibility.
- Create a script `scripts/create-agents.sh` or `scripts/setup-agents.py` that provisions all required agents in the Foundry project. This script must be idempotent (skip if agent already exists).
- The architecture must determine which agents are needed. At minimum, consider:
  - **Prompt Safety Agent** — screens user input for injection attacks, cross-tenant data requests
  - **SQL Generator Agent** — translates natural language to T-SQL SELECT queries using schema context
  - **SQL Validator Agent** — validates generated SQL against security rules (could be deterministic, not necessarily an LLM agent)
  - **Response Formatter Agent** — converts raw query results into natural-language answers
  - An **Orchestrator** that coordinates the above using Agent Framework patterns
- Perform a thorough architecture analysis to determine the optimal set of agents. Document your design decisions.

### 4. Orchestration — Microsoft Agent Framework

- Orchestration must use the **built-in patterns** of Microsoft Agent Framework: `SequentialOrchestration`, `HandoffOrchestration`, or `GroupChatOrchestration` from `agent-framework-orchestrations`.
- Do NOT implement a manual Python pipeline with if/else — use the framework's orchestration primitives.
- The orchestration layer must be deployed as a **separate Azure Container App** (`inriver-dev-orchestrator`) alongside the backend and frontend.
- The backend API receives the query, authenticates and authorizes the user, resolves the database, and calls the orchestration service.
- The orchestration service runs the agent pipeline and returns the result.
- Communication between backend and orchestrator can be synchronous HTTP (for PoC) or async via Azure Service Bus (for production — not required now).

### 5. Secure SQL Access

- Only `SELECT` queries are allowed. No INSERT/UPDATE/DELETE/DROP/ALTER/EXEC.
- SQL validation must use AST-level parsing (`sqlglot`) — not regex.
- The Data Access Layer is the ONLY component that executes SQL.
- Tenant database connection strings are resolved server-side from the authenticated user's domain.
- All query attempts (approved and rejected) must be audit-logged (NDJSON + structlog).
- The backend must have a mock data access fallback for local development without Azure SQL.
- SQL execution uses `aioodbc`/`pyodbc` with Azure AD token authentication (`DefaultAzureCredential` or `ManagedIdentityCredential` based on environment).

### 6. Frontend — React SPA

- Technology: React 19 + TypeScript + Tailwind CSS + Vite.
- **No MSAL** — custom login form (email + password).
- After login, show the chat interface directly. No database selector dropdown.
- Show which database the user is connected to as a read-only badge/indicator.
- Chat UI components: ChatWindow, MessageBubble, QueryInput, ResultsTable.
- Show generated SQL in a collapsible detail below each response.
- Error boundary components for graceful error handling.
- Store auth tokens in memory (React state/context), not localStorage.
- Use `fetch` for API calls — no axios.
- Use Zustand for state management.
- Nginx serves the production build with SPA routing (no server-side API proxy — the frontend calls the backend URL directly).

### 7. Backend API — FastAPI

- Technology: Python 3.13 + FastAPI + Pydantic + structlog.
- API versioning: all routes under `/api/v1/`.
- Endpoints:
  - `POST /api/v1/auth/login` — authenticate, return tokens
  - `POST /api/v1/auth/refresh` — refresh access token
  - `GET /api/v1/databases` — list authorized databases for the user
  - `POST /api/v1/query` — submit a natural-language query
  - `GET /health` — health check (no auth)
  - `GET /ready` — readiness check
- Swagger/OpenAPI auto-docs enabled at `/docs`.
- Health and readiness probes properly configured.
- CORS configured for localhost dev ports and Container Apps domain.
- JWT validation middleware extracts user identity and domain on every authenticated request.

### 8. Infrastructure

- All resources deploy to Azure resource group `RG-InRiver` in `swedencentral`.
- The existing Bicep modules and deploy scripts must be extended (not replaced) to support new requirements:
  - Add `db-users` database to the SQL module
  - Add a third Container App for the orchestrator service
  - Add agent provisioning to the deployment pipeline
- The `deploy.sh` must run the full pipeline: preflight → Bicep → Docker build+push → seed databases → create agents → grant SQL access → setup env vars.
- Docker Compose must support local full-stack development (backend + frontend + orchestrator).

---

## 📦 TECH STACK (MANDATORY)

| Component | Technology |
|---|---|
| Frontend | React 19 + TypeScript + Vite + Tailwind CSS + Zustand |
| Backend API | Python 3.13 + FastAPI + Pydantic + structlog |
| Auth | Custom (bcrypt + JWT HS256) — NOT Entra ID/MSAL |
| Agents | PromptAgents in Azure AI Foundry (created via `azure-ai-projects` SDK) |
| Agent consumption | `FoundryAgent` from `agent-framework-foundry` |
| Orchestration | Microsoft Agent Framework orchestration patterns (`agent-framework-orchestrations`) |
| SQL validation | `sqlglot` (AST parsing) |
| Database | Azure SQL (db-acme, db-nova, db-apex, db-users) |
| SQL access | `aioodbc` + `pyodbc` + Azure AD token auth |
| IaC | Bicep |
| Containers | Azure Container Apps (frontend, backend, orchestrator) |
| Registry | Azure Container Registry |
| AI Model | `gpt-5.4` deployed in Azure AI Foundry |
| Node.js | v24 (for frontend build) |
| Nginx | v1.28 (for frontend serving) |

---

## 📋 EXECUTION INSTRUCTIONS

### Phase 1: Planning & Issue Creation

Before writing ANY code:

1. **Analyze the full architecture** — read the existing files in `docs/design/`, `infra/`, `scripts/`, `database/` to understand the current state.
2. **Design the agent architecture** — determine exactly which PromptAgents are needed, their instructions, tools, and how they interact.
3. **Create GitHub Issues** for ALL work items using the GitHub MCP tool. Structure as Epics → Tasks:
   - Each Epic is a major workstream (Auth, Agents, Orchestration, Frontend, Backend, Infra, Testing).
   - Each Task is an implementable unit of work.
   - **All issues must have labels with emojis** for visual identification:
     - `🏗️ epic` — Epic/workstream
     - `🔧 backend` — Backend work
     - `⚛️ frontend` — Frontend work
     - `🤖 agents` — AI agent work
     - `🔗 orchestration` — Orchestration work
     - `☁️ infra` — Infrastructure/IaC
     - `🔒 security` — Security-related
     - `🧪 testing` — Test work
     - `📄 docs` — Documentation
     - `🔀 parallelizable` — Can be done in parallel with other tasks
     - `🚀 deploy` — Deployment-related
     - `🐛 bug` — Bug fix
   - **Identify parallelizable tasks** and label them with `🔀 parallelizable`. Tasks that don't depend on each other should be marked so subagents can execute them concurrently.
   - Each issue must have: clear title, description with acceptance criteria, labels, and estimated effort (S/M/L in the description).
4. **Create the labels first** in the GitHub repo before creating issues.

### Phase 2: Implementation

Execute the issues in dependency order. For parallelizable tasks, spawn subagents.

**Every implementation must include:**
- Source code
- Unit tests (pytest for Python, vitest for TypeScript)
- Documentation (docstrings, README updates as needed)

**Repository structure to create:**
```
backend/
  app/
    __init__.py
    main.py                  # FastAPI app
    config.py                # Settings
    auth/
      __init__.py
      models.py              # User, Token models
      service.py             # Auth logic (login, JWT, password hashing)
      dependencies.py        # FastAPI dependencies (get_current_user)
      domain_resolver.py     # email domain → database mapping
    api/
      __init__.py
      v1/
        __init__.py
        auth.py              # /api/v1/auth/* routes  
        query.py             # /api/v1/query route
        databases.py         # /api/v1/databases route
    db/
      __init__.py
      connection.py          # Tenant-scoped connection manager
      user_db.py             # User database operations
      schema_cache.py        # Schema metadata cache
    agents/
      __init__.py
      registry.py            # Agent creation/discovery in Foundry
    guardrails/
      __init__.py
      sql_validator.py       # AST-level SQL validation
    observability/
      __init__.py
      audit_logger.py        # NDJSON audit logging
  tests/
    __init__.py
    conftest.py
    test_auth.py
    test_domain_resolver.py
    test_sql_validator.py
    test_tenant_isolation.py
  Dockerfile
  requirements.txt
  .env.example
  pytest.ini

orchestrator/
  app/
    __init__.py
    main.py                  # FastAPI app for orchestration service
    config.py
    pipeline.py              # MAF orchestration (SequentialOrchestration/HandoffOrchestration)
    agents/
      __init__.py
      safety.py              # PromptSafety FoundryAgent wrapper
      sql_generator.py       # SQLGenerator FoundryAgent wrapper
      formatter.py           # ResponseFormatter FoundryAgent wrapper
    tools/
      __init__.py
      sql_validator.py       # FunctionTool for SQL validation
      sql_executor.py        # FunctionTool for SQL execution
      schema_provider.py     # FunctionTool for schema context
  tests/
    __init__.py
    test_pipeline.py
    test_tools.py
  Dockerfile
  requirements.txt
  .env.example

frontend/
  src/
    main.tsx
    App.tsx
    index.css
    auth/
      LoginForm.tsx
      AuthContext.tsx
      useAuth.ts
    api/
      client.ts
      queries.ts
    components/
      ChatWindow.tsx
      MessageBubble.tsx
      QueryInput.tsx
      ResultsTable.tsx
      Header.tsx
      DatabaseBadge.tsx
    store/
      chatStore.ts
    types/
      index.ts
  public/
  index.html
  nginx.conf
  Dockerfile
  package.json
  tsconfig.json
  vite.config.ts
  tailwind.config.js
  postcss.config.js
  .env.example
  .env.production

database/
  schema.sql                 # PIM schema (existing)
  users-schema.sql           # Users + domain_database_map schema
  seed-acme.sql              # (existing)
  seed-nova.sql              # (existing)
  seed-apex.sql              # (existing)
  seed-users.sql             # Test users + domain mappings

scripts/
  deploy.sh                  # (existing — extend)
  preflight.sh               # (existing — extend)
  teardown.sh                # (existing — extend)
  seed-databases.sh          # (existing — extend for db-users)
  grant-sql-access.sh        # (existing)
  setup-agents.py            # NEW: Create PromptAgents in Foundry
  
infra/
  main.bicep                 # (existing — extend)
  modules/                   # (existing — extend container-apps.bicep for orchestrator)

docker-compose.yml           # (existing — extend for 3 services)
```

### Phase 3: Validation

- All tests must pass: `cd backend && pytest` and `cd orchestrator && pytest`
- Frontend must build: `cd frontend && npm run build`
- Bicep must compile: `az bicep build --file infra/main.bicep`
- Docker images must build for all 3 services
- Security tests must verify tenant isolation (user A cannot access user B's database)

---

## ⚠️ CRITICAL CONSTRAINTS

1. **DO NOT use Microsoft Entra ID / MSAL** for user authentication. Use custom email/password auth with JWT.
2. **DO NOT allow the frontend to select which database to query.** Database access is determined server-side from the authenticated user's email domain.
3. **ALL agents must be PromptAgents registered in Azure AI Foundry**, not transient in-process objects. Use `FoundryAgent` to consume them.
4. **Use Agent Framework orchestration patterns**, not manual Python pipelines.
5. **The orchestrator must be a separate Container App.**
6. **All code in English.** Chat interactions follow the user's language.
7. **Every feature must include tests and documentation.** Nothing is done without tests.
8. **Use the GitHub MCP tool to create issues, labels, and manage the backlog.**
9. **Mark parallelizable tasks** with the `🔀 parallelizable` label so subagents can execute them concurrently.
10. **Passwords must be hashed with bcrypt.** Never store plain text passwords.
11. **SQL execution uses AST validation (sqlglot).** Only SELECT queries allowed.
12. **Audit log every query attempt** — approved and rejected.

---

## 🔗 KEY REFERENCES

- Microsoft Agent Framework: https://github.com/microsoft/agent-framework
- `FoundryAgent` class: `from agent_framework.foundry import FoundryAgent`
- `FoundryChatClient` class: `from agent_framework.foundry import FoundryChatClient`
- Agent creation: `azure.ai.projects.aio.AIProjectClient.agents.create_agent()`
- Orchestration patterns: `from agent_framework.orchestrations import SequentialOrchestration, HandoffOrchestration`
- GitHub repo: https://github.com/frdeange/InRiver-DataCase
- Branch: `dev`
- Azure resource group: `RG-InRiver`
- Azure region: `swedencentral`
- AI Foundry project endpoint: check deployment outputs or `.env`
- Model deployment: `gpt-5.4` (version `2026-03-05`)

---

## 🚀 START

Begin by reading all existing files in the repository to understand the current state. Then design the architecture, create the GitHub issues with labels, and implement phase by phase. Ask for clarification if any requirement is ambiguous — do not assume.
