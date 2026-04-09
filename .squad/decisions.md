# Squad Decisions

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction

---

## ADR-001: System Architecture — InRiver Agentic SQL PoC

**Author:** Danny (Lead Architect) | **Date:** 2025-04-09 | **Status:** Accepted  
**Source:** `.squad/decisions/inbox/danny-adr-architecture.md`

### Problem Statement
InRiver needs a PoC demonstrating an AI agent that can safely answer natural-language questions about product data in Azure SQL, with security, multi-tenancy, auditability, and Entra ID authentication.

### Stack Decisions

| Area | Decision | Rationale |
|---|---|---|
| Backend | **FastAPI (Python)** | Native async, auto-generated OpenAPI docs, Pydantic validation, first-class Azure SDK |
| Frontend | **React + TypeScript + Vite + MSAL Browser** | MSAL is Microsoft's official Entra ID browser library; Vite for fast iteration |
| Auth | **Microsoft Entra ID (OIDC/OAuth2)** | Already in InRiver's tenant; JWT group claims drive RBAC; credible security story |
| Database | **Azure SQL — 3 separate databases** | True isolation story; mirrors InRiver's actual per-customer deployment model |
| AI | **Azure OpenAI GPT-4.1 via AI Foundry** | Stays within Azure trust boundary; function calling for structured SQL output |
| Hosting | **Azure Container Apps** | Scales to zero, Managed Identity, Docker dev-prod parity |
| Guardrails | **sqlparse AST-based validation** | AST beats regex; catches obfuscated attacks; fully auditable; pure Python |
| Secrets | **Azure Key Vault + Managed Identity** | No secrets in env vars or code; Container Apps reference pattern |
| IaC | **Bicep** | Azure-native; no state file; ARM-familiar team |

### Security Architecture (summary)
- **Three independent gates:** Prompt Safety → SQL Validator → RBAC → DB
- **SQL allowlist:** SELECT only, no DDL/DML/DCL, no system tables, no comments, no multi-statement
- **DB login is read-only:** Even a guardrail bypass cannot write
- **RBAC:** Entra group → permitted database set; 403 before any AI call if check fails
- **Prompt injection:** `<user_query>` delimiter separation; JSON-only output format; no RAG feedback loop
- **Audit trail:** Every request logged to App Insights (metadata only — no result rows, no full JWT, no connection strings)

---

## DevContainer & IaC Decisions

**Author:** Livingston (DevOps) | **Date:** 2025-04-09 | **Status:** Accepted  
**Source:** `.squad/decisions/inbox/livingston-devcontainer-infra.md`

### DevContainer
- **Parallel `postCreateCommand` (object form):** Allows independent setup steps (pip, ODBC, npm) to run concurrently.
- **MSODBCSQL18 install:** `msodbcsql18` + `mssql-tools18` + `unixodbc-dev` via `apt-get` in `postCreateCommand`. ⚠️ Uses deprecated `apt-key add` — should migrate to `gpg --dearmor` before production use.
- **Ports forwarded:** 3000 (React), 8000 (FastAPI).
- **Extensions added:** Bicep, MSSQL, ESLint, Prettier, Python, Black.

### IaC
- **Bicep over Terraform:** Azure-native, no state file, simpler for this PoC.
- **SQL Serverless (GP_S_Gen5_1):** `autoPauseDelay: 60 min`, `minCapacity: 0.5 vCore`, local backup redundancy — cost-minimised for idle demo.
- **Key Vault RBAC mode** (`enableRbacAuthorization: true`): Modern; avoids per-identity access policy sprawl. Managed Identity gets **Key Vault Secrets User** (read-only).
- **Key Vault purge protection OFF:** Intentional for demo (allows clean resource group teardown). **Must be enabled for production.**
- **Container Apps — `minReplicas: 0`:** Scales to zero when idle.
- **User-assigned Managed Identity:** Pre-created before container apps exist; reusable across apps.
- **Placeholder container images:** `containerapps-helloworld` used initially; CI/CD will replace.
- **Entra App Registration not automated in Bicep:** Requires Graph API permissions; documented as manual post-deploy step.

### Open items (Livingston)
1. `ai_agent_ro` SQL login creation script (Data Engineer task).
2. CI/CD pipeline for image build/push/deploy.
3. Migrate ODBC `apt-key add` to `gpg --dearmor`.

---

## Backend & Database Decisions

**Author:** Rusty (Backend Dev) | **Date:** 2025-04-09 | **Status:** Accepted  
**Source:** `.squad/decisions/inbox/rusty-backend-db.md`

- **EAV schema for product attributes:** Mirrors InRiver's actual data model (arbitrary typed attributes without migrations). `data_type` column drives which value column (`text_value`, `number_value`, `bool_value`, `date_value`) is populated. Trade-off: queries require JOINs — acceptable for PoC; AI prompt explains the pattern.
- **Static schema context (not live introspection):** `schema_context.py` provides a curated schema description. Avoids giving the model metadata access; no extra DB round-trip; guides model toward correct EAV usage.
- **OpenAI function calling (`tool_choice: required`):** Structured `{ sql, explanation }` output — no regex parsing of free text.
- **Single retry loop:** Agent retries exactly once on guardrail rejection or DB error, passing the error back to the model. Second failure surfaces 403 or 502. Keeps latency predictable.
- **Stub-first integration with Linus:** All security modules imported with `try/except ImportError` fallbacks in `api/stubs.py`. Real implementations supersede stubs automatically.
- **`pydantic-settings` added:** Pydantic v2 ships `BaseSettings` in a separate package.
- **JWKS cache with forced refresh on unknown `kid`:** Avoids false 401s during Entra key rotations.

### Interface contracts (Rusty → Linus)

| Path | Signature |
|---|---|
| `app.auth.validator.validate_token` | `(token: str) -> dict` |
| `app.guardrails.rbac.check_rbac` | `(claims: dict, customer_db: str) -> bool` |
| `app.guardrails.rbac.get_permitted_dbs` | `(claims: dict) -> list[str]` |
| `app.guardrails.sql_validator.validate_sql` | `(sql: str) -> None` — raises `ValueError` on rejection |
| `app.guardrails.prompt_safety.check_prompt_safety` | `(question: str) -> None` — raises `ValueError` on rejection |

---

## Security Guardrails Decisions

**Author:** Linus (AI & Security) | **Date:** 2025-04-09 | **Status:** Accepted  
**Source:** `.squad/decisions/inbox/linus-security-guardrails.md`

- **Defence in depth — three independent gates:** Prompt Safety → SQL Validator → RBAC → DB. Bypassing one gate does not help an attacker.
- **SQL validation via `sqlparse` AST, not regex alone:** AST-level token classification is not fooled by case variations, whitespace, or Unicode tricks. Regex supplements for things sqlparse doesn't classify (e.g. `xp_cmdshell`, `OPENROWSET`).
- **UNION SELECT allowed but flagged:** Legitimate for analytics queries. Returns `risk_level="low"` for audit alerting without blocking.
- **SQL comments always rejected:** `--` and `/* */` have no legitimate use in AI-generated queries; primary carrier for injection payloads. A tiny number of edge-case queries blocked — security wins.
- **Prompt safety uses regex + heuristics (not a second LLM call):** Second LLM adds latency, cost, and can itself be jailbroken. Regex is fast, deterministic, and auditable. ALL-CAPS directive heuristic catches novel phrasing.
- **RBAC hard allowlist of DB names:** `customer_db` checked against `frozenset{"acme", "nova", "apex"}` before any permission lookup. Forged JWT database claims cannot reach an unmanaged database.
- **Audit logger never records query content:** `question_length`, `sql_length`, `risk_level`, `execution_success`, `row_count` only. No PII; no schema information in logs.
- **`SIGHUP` triggers permissions reload** without restart (supports live key-rotation and permission updates).

### Interfaces (Linus → Rusty)

```python
from app.guardrails.sql_validator import validate_sql, SQLValidationResult
from app.guardrails.prompt_safety import check_prompt_safety, PromptSafetyResult
from app.auth.rbac import check_database_access, get_user_databases, get_user_role
from app.observability.audit_logger import log_query_event
```

All validation is purely in-memory — no network or DB calls from these modules.

---

## Frontend Architecture Decisions

**Author:** Basher (Frontend Dev) | **Date:** 2025-04-09 | **Status:** Accepted  
**Source:** `.squad/decisions/inbox/basher-frontend.md`

- **MSAL Redirect Flow (not Popup):** More reliable on mobile; avoids popup blockers. Token state in `sessionStorage` — survives refresh, not new tabs (security boundary).
- **Local component state (no Redux/Zustand):** Single-page, single primary interaction. `useState` + prop drilling is sufficient for PoC scope.
- **Axios interceptor for auth:** Module-level `tokenGetter` set at init; `TokenSetter` bridges MSAL hooks to axios client. Keeps components clean; centralises auth concerns.
- **Chat-style UI:** Natural language queries map to conversational interface. Results table + SQL embedded in assistant "bubble."
- **Tailwind CSS (no component library):** Full control, minimal bundle, professional B2B aesthetic. MUI/Ant Design would be overkill.
- **Vite dev proxy for CORS:** `/api` proxied to `http://localhost:8000` in dev. Production uses nginx `try_files` for SPA routing.
- **TypeScript strict mode:** Team-facing tool; type safety reduces debugging time.
