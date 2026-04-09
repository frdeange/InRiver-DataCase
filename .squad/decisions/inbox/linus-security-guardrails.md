# Decision: Security Guardrails Architecture

**Author:** Linus (AI & Security)  
**Date:** 2025-01-01  
**Status:** Accepted

## Context

The InRiver-DataCase PoC lets an authenticated user ask natural-language questions that are turned into SQL by GPT-4.1 and executed against one of several Azure SQL databases, each representing a different customer tenant.  This creates three distinct attack surfaces:

1. **AI-generated malicious SQL** — a clever prompt can cause the LLM to emit DDL/DML, system table queries, or stacked queries.
2. **Prompt injection** — a user embeds instructions inside their question to override the system prompt.
3. **Tenant data leakage** — a user accesses a database they are not authorised for, either by guessing a connection string or by convincing the AI to target one.

## Decisions

### D1 — Defence in depth with three independent gates

Rather than relying on the LLM alone to refuse dangerous requests, we added three independent in-process gates that all inputs must pass before any query is executed:

```
User question → [Prompt Safety] → [SQL Validator] → [RBAC] → DB
```

Each gate can independently reject the request.  Bypassing one does not help an attacker unless all three are bypassed simultaneously.

**Alternative considered:** Rely solely on the LLM system prompt to refuse harmful requests.  Rejected — LLMs are probabilistic and jailbreaks are continuously discovered.

### D2 — SQL validation via sqlparse AST, not regex alone

`sqlparse` parses the SQL into a token stream and classifies each token by type (DDL, DML, Keyword, …).  This is more robust than naive string matching because it is not fooled by case variations, extra whitespace, or Unicode tricks.

We still augment with regex for things sqlparse does not classify as keywords (e.g. `xp_cmdshell`, `OPENROWSET`) — but the primary defence uses the AST.

**Key insight:** `SELECT` itself carries the DML token type in sqlparse.  The validator explicitly whitelists it while rejecting all other DML tokens.

### D3 — UNION SELECT is allowed but flagged

UNION is legitimate for some analytics queries (e.g. combining current and archived data).  Blocking it entirely would hurt usability.  We allow it but return `risk_level="low"` so the audit trail can alert on unusual patterns without blocking legitimate use.

**Rejected alternative:** Block UNION entirely.  Too restrictive for a data-analytics tool.

### D4 — SQL comments are always rejected

`--` and `/* */` comments have no legitimate use in AI-generated queries and are the primary carrier for injection payloads (e.g. `'; DROP TABLE users --`).  We reject them unconditionally even though this means a tiny number of edge-case queries are blocked.

**Trade-off accepted:** A handful of complex queries that legitimately use comments (very unusual in AI output) will be rejected.  Security wins.

### D5 — Prompt safety uses regex + heuristics, not a second LLM call

A second LLM call to classify prompts would add latency and cost and could itself be jailbroken.  Regex-based pattern matching against a known set of injection phrases is fast, deterministic, and auditable.  The ALL-CAPS directive heuristic catches novel phrasing that doesn't match any specific pattern.

### D6 — RBAC uses a hard allowlist of database names

The `customer_db` value from the request is checked against a hard-coded frozenset `{"acme", "nova", "apex"}` before any permission lookup.  This ensures that even if an attacker crafts a JWT with a forged database claim, they cannot access a database we don't manage.

The JSON permissions file is loaded at startup and cached.  A `SIGHUP` signal triggers a reload without restarting the process — supporting operational key-rotation and permission updates in a running service.

### D7 — Audit logger never records query content

The actual SQL and question text are never written to logs — they may contain PII (e.g. customer names in a WHERE clause) or sensitive schema information (table/column names).  Only metadata proxies are logged: `question_length`, `sql_length`, `risk_level`, `execution_success`, `row_count`.

App Insights integration is conditional on `APPINSIGHTS_CONNECTION_STRING` being set so that the module works in local development without the SDK installed.

## Interfaces for Rusty (backend)

```python
from app.guardrails.sql_validator import validate_sql, SQLValidationResult
from app.guardrails.prompt_safety import check_prompt_safety, PromptSafetyResult
from app.auth.rbac import check_database_access, get_user_databases, get_user_role
from app.observability.audit_logger import log_query_event
```

All validation is purely in-memory.  No network or DB calls from these modules.

## Files created

| File | Purpose |
|---|---|
| `backend/app/guardrails/__init__.py` | Package marker |
| `backend/app/guardrails/sql_validator.py` | SQL AST validation |
| `backend/app/guardrails/prompt_safety.py` | Prompt injection detection |
| `backend/app/auth/__init__.py` | Package marker |
| `backend/app/auth/rbac.py` | RBAC / tenant data isolation |
| `backend/app/auth/permissions.json` | Demo user → database mappings |
| `backend/app/observability/__init__.py` | Package marker |
| `backend/app/observability/audit_logger.py` | Structured audit event emitter |
| `backend/tests/__init__.py` | Package marker |
| `backend/tests/conftest.py` | Pytest fixtures |
| `backend/tests/test_guardrails.py` | 46 security tests (all passing) |

## Dependencies added

- `sqlparse` — SQL parsing library (needs to be added to `requirements.txt`)
- `opencensus-ext-azure` — Optional; only needed when App Insights is configured
