## 6. Secure SQL Access Strategy

This section defines the security architecture for how AI agents generate, validate, and execute SQL against tenant databases. This is the most security-critical layer of InRiver-DataCase — every design decision here assumes a hostile input model where user questions, AI outputs, and intermediate state are all untrusted.

---

### 6.1 Architecture Decision: No Raw SQL Execution by Agents

**Decision:** AI agents MUST NOT hold database connections, execute SQL, or receive raw query results directly.

| Principle | Enforcement |
|-----------|-------------|
| Agents never hold a connection | No `Connection` or `Engine` objects are injected into agent classes |
| SQL generation ≠ SQL execution | Separated by a mandatory validation boundary |
| Only the DAL executes SQL | The Data Access Layer is a backend service class, not an agent |
| DAL rejects unvalidated SQL | The DAL's `execute()` method requires a `ValidatedQuery` object — raw SQL strings are not accepted |
| Results are sanitized before return | The DAL returns typed result sets; agents never see raw `Row` objects |

**Why this matters:** LLM-generated SQL is adversarial input. The model can hallucinate table names, inject malicious clauses, or produce syntactically valid but semantically dangerous queries. By treating generated SQL as untrusted data that must pass through a validation gate before reaching the database, we contain the blast radius of any generation failure.

```
Agent boundary                          │  Backend service boundary
─────────────────────────────────────── │ ─────────────────────────────────────
                                        │
  Orchestrator Agent                    │
  SQL Generator Agent                   │   SQL Validator (guardrail)
  Response Formatter Agent              │   Data Access Layer (executes SQL)
                                        │   Audit Logger
                                        │
  These components produce/consume      │   These components touch the database
  text only. No DB access.              │   and enforce security invariants.
```

---

### 6.2 SQL Generation Pipeline

Every user question follows this exact pipeline. No step may be skipped or reordered.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        SQL Generation Pipeline                               │
│                                                                              │
│  ┌─────────┐    ┌───────────────┐    ┌──────────────┐    ┌───────────────┐  │
│  │  User    │    │  Orchestrator │    │ SQL Generator│    │ SQL Validator │  │
│  │ Question │───▶│  Agent        │───▶│ Agent        │───▶│ (Guardrail)  │  │
│  └─────────┘    └───────────────┘    └──────────────┘    └──────┬───────┘  │
│                                                                  │          │
│                        ┌─────────────────────────────────────────┘          │
│                        │                                                    │
│                        ▼                                                    │
│               ┌─────────────────┐                                           │
│               │ Validation      │                                           │
│               │ PASS?           │                                           │
│               └────┬───────┬────┘                                           │
│                    │       │                                                │
│               YES  │       │  NO                                            │
│                    ▼       ▼                                                │
│  ┌─────────────────────┐  ┌──────────────────────┐                         │
│  │ Data Access Layer   │  │ Rejection Response   │                         │
│  │ (tenant-scoped      │  │ (logged + user-      │                         │
│  │  connection)        │  │  friendly error)     │                         │
│  └──────────┬──────────┘  └──────────────────────┘                         │
│             │                                                               │
│             ▼                                                               │
│  ┌─────────────────────┐                                                    │
│  │ Response Formatter  │                                                    │
│  │ Agent               │───▶  User-friendly answer                         │
│  └─────────────────────┘                                                    │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Step-by-step detail:**

| Step | Component | Input | Output | Trust Level |
|------|-----------|-------|--------|-------------|
| 1 | **Orchestrator Agent** | User's natural language question + auth context | Classified intent (query, clarification, refusal) | Untrusted (user input) |
| 2 | **SQL Generator Agent** | Intent + schema context + tenant constraints | SQL string + parameter bindings | Untrusted (LLM output) |
| 3 | **SQL Validator** | Generated SQL + tenant schema definition | `ValidatedQuery` or `RejectionResult` | Trusted after validation |
| 4 | **Data Access Layer** | `ValidatedQuery` + tenant ID | `QueryResultSet` (typed rows, capped) | Trusted |
| 5 | **Response Formatter Agent** | `QueryResultSet` + original question | Natural language answer | Output (sanitized) |

---

### 6.3 SQL Validation Rules

The SQL Validator is the critical security gate. It uses AST-level analysis (not regex) to inspect every generated query before execution.

#### 6.3.1 Allowlisted Operations

For the PoC, only `SELECT` statements are permitted. This is enforced at the AST level, not by string matching.

```python
ALLOWED_STATEMENT_TYPES = {"SELECT"}

# Explicitly blocked — even if the LLM "explains" why it's needed:
BLOCKED_STATEMENT_TYPES = {
    "INSERT", "UPDATE", "DELETE", "DROP", "ALTER", "CREATE",
    "TRUNCATE", "MERGE", "EXEC", "EXECUTE", "GRANT", "REVOKE",
    "BACKUP", "RESTORE", "BULK", "RECONFIGURE",
}
```

#### 6.3.2 Schema Validation

Generated SQL must reference only tables and columns that exist in the tenant's schema definition.

- Parse all table references (including aliases) and resolve them against the tenant's `SchemaDefinition`
- Parse all column references and verify they belong to referenced tables
- Reject any reference to a table or column not in the schema
- Reject `SELECT *` — force explicit column lists (prevents accidental exposure of new columns added later)

#### 6.3.3 Tenant Scoping

Every query is scoped to a single tenant database. The following patterns are **blocked**:

| Pattern | Detection | Risk |
|---------|-----------|------|
| Cross-database references (`db_name.schema.table`) | AST: compound identifier with 3+ parts | Cross-tenant data access |
| Linked server queries (`servername.db.schema.table`) | AST: compound identifier with 4 parts | Remote server access |
| `OPENROWSET` / `OPENDATASOURCE` | AST: function name check | File system / remote access |
| `USE [database]` | AST: statement type | Database switching |
| `xp_cmdshell`, `sp_OA*` | Function/procedure name blocklist | OS command execution |

#### 6.3.4 Parameterization

All user-provided values must be parameterized. The SQL Generator Agent is prompted to output parameterized SQL with a separate parameter dict.

```python
# ACCEPTED — parameterized
sql = "SELECT name, sku FROM products WHERE category = @category"
params = {"category": "Electronics"}

# REJECTED — string interpolation detected
sql = "SELECT name, sku FROM products WHERE category = 'Electronics'"
# Validator flags inline string literals that match user input tokens
```

The validator checks:
- `WHERE` clause values should be parameters (`@param_name`), not literals
- `LIKE` patterns should be parameterized with proper escaping
- `IN` lists should use parameterized TVPs or individual parameters
- No string concatenation operators (`+` on string types)

#### 6.3.5 Query Complexity Limits

| Limit | Value (PoC) | Rationale |
|-------|-------------|-----------|
| Max `JOIN` count | 4 | Prevent runaway cartesian products |
| Max result rows | 500 | Controlled via injected `TOP 500` |
| Execution timeout | 15 seconds | Prevents long-running analytical queries |
| Max subquery depth | 2 | Limits complexity |
| Max `UNION` clauses | 2 | Prevents result set inflation |

The DAL injects `SET ROWCOUNT 500` before execution as a server-side safety net, independent of any `TOP` clause in the generated SQL.

#### 6.3.6 Blocked Patterns

```python
BLOCKED_PATTERNS = [
    # System catalog access
    r"sys\.\w+",
    r"INFORMATION_SCHEMA\.\w+",       # blocked in generated SQL; used only in schema loader
    # Dynamic SQL
    r"EXEC\s*\(",
    r"sp_executesql",
    r"EXECUTE\s+\(",
    # SQL comments (potential injection vector)
    r"--",
    r"/\*",
    # Batching
    r"\bGO\b",
    # Variable declarations (prevents state manipulation)
    r"DECLARE\s+@",
    r"SET\s+@",
    # Wait-based attacks
    r"WAITFOR\b",
]
```

> **Note on INFORMATION_SCHEMA:** The schema loader service (Section 6.4) reads `INFORMATION_SCHEMA` at startup using a dedicated, non-agent connection. Generated SQL from agents must never reference it.

---

### 6.4 Schema Context Management

The SQL Generator Agent needs schema awareness to produce valid SQL. This is provided through pre-loaded, curated schema definitions — not by letting the agent query the database.

#### 6.4.1 Schema Definition Structure

```python
@dataclass(frozen=True)
class ColumnDef:
    name: str
    data_type: str          # e.g., "nvarchar(255)", "int", "datetime2"
    is_nullable: bool
    description: str        # human-readable, used in LLM prompt context

@dataclass(frozen=True)
class TableDef:
    schema_name: str        # e.g., "dbo"
    table_name: str
    columns: tuple[ColumnDef, ...]
    description: str        # what this table represents in business terms
    row_count_estimate: int # helps LLM understand table size

@dataclass(frozen=True)
class ForeignKeyDef:
    from_table: str
    from_column: str
    to_table: str
    to_column: str

@dataclass(frozen=True)
class SchemaDefinition:
    tenant_id: str
    tables: tuple[TableDef, ...]
    foreign_keys: tuple[ForeignKeyDef, ...]
    last_refreshed: datetime
```

#### 6.4.2 Schema Loading

Schemas are loaded at application startup and cached in memory. The loader connects to each tenant database using a dedicated read-only service principal and reads `INFORMATION_SCHEMA.TABLES`, `INFORMATION_SCHEMA.COLUMNS`, and `INFORMATION_SCHEMA.KEY_COLUMN_USAGE`.

```python
class SchemaLoader:
    """Loads schema definitions from tenant databases at startup."""

    async def load_schema(self, tenant_id: str, conn: AsyncConnection) -> SchemaDefinition:
        # Uses INFORMATION_SCHEMA — this is the ONLY code path allowed to do so
        tables = await conn.execute(text(
            "SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES "
            "WHERE TABLE_TYPE = 'BASE TABLE'"
        ))
        # ... build SchemaDefinition
```

#### 6.4.3 Schema Caching Strategy

| Aspect | Strategy |
|--------|----------|
| Cache location | In-memory (`dict[str, SchemaDefinition]`) |
| Cache lifetime | Refreshed every 6 hours or on explicit reload via admin endpoint |
| Invalidation | Manual trigger via `/admin/schema/refresh/{tenant_id}` (admin-only) |
| Cold start | Loaded synchronously during app startup (`lifespan` event) — the app does not serve requests until all schemas are cached |
| Immutability | `SchemaDefinition` is a frozen dataclass — cannot be mutated after creation |

#### 6.4.4 Prompt Context Injection

The schema is injected into the SQL Generator Agent's system prompt as a compact text block:

```
You have access to the following database schema for tenant "{tenant_id}":

Table: dbo.Products
  - ProductId (int, PK) — Unique product identifier
  - Name (nvarchar(255)) — Product display name
  - SKU (nvarchar(50)) — Stock keeping unit
  - CategoryId (int, FK → dbo.Categories.CategoryId) — Product category
  - Price (decimal(18,2)) — Unit price
  ...

Relationships:
  - Products.CategoryId → Categories.CategoryId
  ...

Rules:
  - Generate SELECT statements ONLY
  - Use parameterized queries with @param_name syntax
  - Reference ONLY the tables and columns listed above
  - Always include explicit column lists (no SELECT *)
```

The context is kept minimal: no sample data, no indexes, no stored procedures. Only structural metadata and business descriptions.

---

### 6.5 Tenant-Scoped Database Connections

#### 6.5.1 Connection Architecture

Each tenant has a dedicated Azure SQL database. Connections are never shared across tenants.

```
                          ┌─────────────────┐
  tenant_id = "acme"  ──▶│ Connection Pool  │──▶  db-acme.database.windows.net
                          │ (max_size=10)    │
                          └─────────────────┘
                          ┌─────────────────┐
  tenant_id = "nova"  ──▶│ Connection Pool  │──▶  db-nova.database.windows.net
                          │ (max_size=10)    │
                          └─────────────────┘
                          ┌─────────────────┐
  tenant_id = "apex"  ──▶│ Connection Pool  │──▶  db-apex.database.windows.net
                          │ (max_size=10)    │
                          └─────────────────┘
```

#### 6.5.2 Connection String Management

| Requirement | Implementation |
|-------------|----------------|
| Storage | Azure Key Vault secrets, one per tenant: `sql-conn-acme`, `sql-conn-nova`, `sql-conn-apex` |
| Local dev | `.env` file with `SQL_CONN_ACME`, `SQL_CONN_NOVA`, `SQL_CONN_APEX` (never committed) |
| Authentication | Azure AD Managed Identity (production) / SQL auth (local dev only) |
| Rotation | Key Vault handles rotation; app re-reads on pool refresh (every 6 hours, aligned with schema refresh) |

#### 6.5.3 Connection Resolution

The tenant is determined from the authenticated user's JWT claims, never from request parameters or AI-generated content.

```python
class TenantConnectionResolver:
    """Resolves a database connection pool from a validated tenant claim."""

    def __init__(self, pools: dict[str, AsyncEngine]):
        self._pools = pools  # pre-initialized at startup

    def get_engine(self, tenant_id: str) -> AsyncEngine:
        engine = self._pools.get(tenant_id)
        if engine is None:
            raise TenantNotFoundError(f"No database configured for tenant: {tenant_id}")
        return engine
```

**Invariants:**
- `tenant_id` comes from the JWT `tid` claim, validated by Entra ID token validation
- The `_pools` dict is populated at startup from configuration — not modifiable at runtime
- There is no code path where user input or LLM output influences which connection is used

#### 6.5.4 Connection Pool Settings

```python
POOL_CONFIG = {
    "pool_size": 5,          # base connections per tenant
    "max_overflow": 5,       # burst capacity
    "pool_timeout": 10,      # seconds to wait for a connection
    "pool_recycle": 1800,    # recycle connections every 30 minutes
    "pool_pre_ping": True,   # validate connections before use
}
```

---

### 6.6 Audit Trail

Every SQL operation — generated, validated, executed, or rejected — is logged. Audit logs are immutable and cannot be modified by any agent or user-facing code path.

#### 6.6.1 Log Schema

```python
@dataclass
class AuditEntry:
    timestamp: datetime              # UTC, ISO 8601
    request_id: str                  # correlation ID for the full request lifecycle
    user_id: str                     # from JWT 'oid' claim
    tenant_id: str                   # from JWT 'tid' claim
    natural_language_query: str      # user's original question
    generated_sql: str | None        # SQL produced by the generator (None if generation failed)
    parameters: dict[str, Any] | None
    validation_result: str           # "PASSED" | "REJECTED"
    rejection_reasons: list[str]     # empty if passed
    execution_result: str | None     # "SUCCESS" | "ERROR" | "TIMEOUT" | None (if not executed)
    row_count: int | None            # rows returned (None if not executed)
    duration_ms: int                 # end-to-end duration
    error_detail: str | None         # internal error (never exposed to user)
```

#### 6.6.2 Log Destinations

| Destination | Format | Purpose |
|-------------|--------|---------|
| Azure Application Insights | Custom events via `opencensus` / `azure-monitor-opentelemetry` | Centralized monitoring, alerting, KQL queries |
| Local NDJSON file | One JSON object per line, rotated daily | Offline analysis, compliance, backup |

```python
# NDJSON output example (one line, shown formatted for readability):
{
  "timestamp": "2026-04-09T14:32:01.442Z",
  "request_id": "req_8f3a2b1c",
  "user_id": "user_abc123",
  "tenant_id": "acme",
  "natural_language_query": "How many products are in the Electronics category?",
  "generated_sql": "SELECT COUNT(*) AS product_count FROM dbo.Products WHERE CategoryId = @category_id",
  "parameters": {"category_id": 3},
  "validation_result": "PASSED",
  "rejection_reasons": [],
  "execution_result": "SUCCESS",
  "row_count": 1,
  "duration_ms": 234,
  "error_detail": null
}
```

#### 6.6.3 Rejected Query Logging

Rejected queries are logged with full context including every validation rule that was violated:

```python
{
  "validation_result": "REJECTED",
  "rejection_reasons": [
    "BLOCKED_STATEMENT: DELETE statement not allowed",
    "BLOCKED_PATTERN: sys.objects reference detected",
    "SCHEMA_VIOLATION: table 'audit_logs' not in tenant schema"
  ],
  "execution_result": null,
  "row_count": null
}
```

---

### 6.7 Error Handling and Graceful Degradation

Every failure mode has a defined user-facing response. Raw SQL errors, stack traces, and internal details are **never** exposed to the user.

#### 6.7.1 Failure Mode Table

| Failure | Internal Action | User-Facing Message |
|---------|----------------|---------------------|
| SQL generation fails (LLM error/timeout) | Log error, increment `sql_gen_failure` metric | "I couldn't understand that question well enough to query the database. Could you rephrase it?" |
| SQL validation rejects query | Log rejection with reasons, increment `sql_validation_rejection` metric | "I generated a query but it didn't pass our safety checks. Could you try asking in a different way?" |
| SQL execution timeout (>15s) | Kill query via `cancel()`, log timeout | "That query took too long to run. Try narrowing your question — for example, filter by category or date range." |
| SQL execution error (syntax, runtime) | Log full error detail internally | "Something went wrong running that query. Our team has been notified." |
| Connection pool exhausted | Log, return 503 with retry-after header | "The system is under heavy load. Please try again in a moment." |
| Schema not loaded for tenant | Log critical error, alert | "We're having trouble connecting to your database. Please contact support." |

#### 6.7.2 Error Response Contract

All error responses follow a consistent structure. The `detail` field never contains SQL, table names, or internal error messages.

```python
class QueryErrorResponse(BaseModel):
    success: bool = False
    message: str                    # user-friendly message
    request_id: str                 # for support reference
    can_retry: bool                 # whether retrying may help
    suggestion: str | None = None   # optional rephrasing hint
```

#### 6.7.3 Retry Strategy

- **LLM generation failures:** Retry once with a simplified prompt (drop schema descriptions, keep only table/column names). If still fails, return error.
- **Validation rejections:** Do NOT retry automatically. The generator produced unsafe SQL — retrying is unlikely to help and may waste tokens.
- **Execution timeouts:** Do NOT retry. The query was too expensive.
- **Transient connection errors:** Retry up to 2 times with exponential backoff (1s, 3s).

---

### 6.8 Python Implementation Patterns

#### 6.8.1 Recommended Libraries

| Concern | Library | Rationale |
|---------|---------|-----------|
| SQL parsing & validation | **`sqlglot`** | Full SQL AST parser with T-SQL dialect support; can parse, transform, and validate SQL structurally. Preferred over `sqlparse` (token-based, not a true AST) and regex (fragile). |
| Async database access | **`sqlalchemy[asyncio]` + `aioodbc`** | SQLAlchemy 2.0 async engine with `aioodbc` driver for Azure SQL. Provides connection pooling, parameterized execution, and async/await support. |
| Parameter binding | **`pyodbc`** (via `aioodbc`) | Native parameterized queries with `?` placeholders, converted from `@name` syntax by the DAL. |
| Audit logging | **`structlog`** | Structured JSON logging with context binding. Outputs NDJSON natively. |
| Azure Key Vault | **`azure-keyvault-secrets`** + **`azure-identity`** | Managed Identity–based secret retrieval. |

#### 6.8.2 Core Interfaces

```python
# === sql_validator.py ===

from dataclasses import dataclass
import sqlglot
from sqlglot import exp

@dataclass(frozen=True)
class ValidatedQuery:
    """Immutable container — proof that SQL passed validation."""
    sql: str
    parameters: dict[str, Any]
    tenant_id: str
    request_id: str

@dataclass(frozen=True)
class RejectionResult:
    reasons: list[str]
    generated_sql: str
    request_id: str

class SQLValidator:
    """AST-level SQL validation against tenant schema and security rules."""

    def __init__(self, schema_registry: dict[str, SchemaDefinition]):
        self._schemas = schema_registry

    def validate(
        self,
        sql: str,
        parameters: dict[str, Any],
        tenant_id: str,
        request_id: str,
    ) -> ValidatedQuery | RejectionResult:
        violations: list[str] = []

        # Parse to AST
        try:
            parsed = sqlglot.parse(sql, dialect="tsql")
        except sqlglot.errors.ParseError as e:
            return RejectionResult(
                reasons=[f"PARSE_ERROR: {e}"],
                generated_sql=sql,
                request_id=request_id,
            )

        # Must be exactly one statement
        if len(parsed) != 1:
            violations.append("MULTI_STATEMENT: only single statements allowed")

        stmt = parsed[0]

        # Must be SELECT
        if not isinstance(stmt, exp.Select):
            violations.append(
                f"BLOCKED_STATEMENT: {type(stmt).__name__} not allowed"
            )

        # Check blocked patterns (belt-and-suspenders alongside AST checks)
        for pattern in BLOCKED_PATTERNS:
            if re.search(pattern, sql, re.IGNORECASE):
                violations.append(f"BLOCKED_PATTERN: matched {pattern}")

        # Schema validation
        schema = self._schemas.get(tenant_id)
        if schema is None:
            violations.append(f"NO_SCHEMA: no schema loaded for tenant {tenant_id}")
        else:
            violations.extend(self._validate_schema_refs(stmt, schema))

        if violations:
            return RejectionResult(
                reasons=violations,
                generated_sql=sql,
                request_id=request_id,
            )

        return ValidatedQuery(
            sql=sql,
            parameters=parameters,
            tenant_id=tenant_id,
            request_id=request_id,
        )
```

```python
# === data_access_layer.py ===

from sqlalchemy.ext.asyncio import AsyncEngine, AsyncConnection
from sqlalchemy import text

class DataAccessLayer:
    """Executes validated SQL against tenant-scoped connections.
    
    This is the ONLY class that touches the database for query execution.
    It accepts ValidatedQuery objects only — raw SQL strings are rejected
    at the type level.
    """

    def __init__(
        self,
        connection_resolver: TenantConnectionResolver,
        audit_logger: AuditLogger,
    ):
        self._resolver = connection_resolver
        self._audit = audit_logger

    async def execute(self, query: ValidatedQuery) -> QueryResultSet:
        engine = self._resolver.get_engine(query.tenant_id)

        async with engine.connect() as conn:
            # Server-side row limit safety net
            await conn.execute(text("SET ROWCOUNT 500"))

            try:
                result = await asyncio.wait_for(
                    conn.execute(
                        text(query.sql),
                        query.parameters,
                    ),
                    timeout=15.0,
                )
                rows = result.fetchall()
                columns = list(result.keys())

                return QueryResultSet(
                    columns=columns,
                    rows=[dict(zip(columns, row)) for row in rows],
                    row_count=len(rows),
                    truncated=len(rows) >= 500,
                )

            except asyncio.TimeoutError:
                # Connection is closed by context manager; query is cancelled
                raise QueryTimeoutError(query.request_id)
```

```python
# === audit_logger.py ===

import structlog
from pathlib import Path

class AuditLogger:
    """Structured audit logging to Application Insights + NDJSON files."""

    def __init__(self, log_dir: Path):
        self._logger = structlog.get_logger("audit")
        self._log_dir = log_dir

    async def log_query(self, entry: AuditEntry) -> None:
        log_data = {
            "timestamp": entry.timestamp.isoformat(),
            "request_id": entry.request_id,
            "user_id": entry.user_id,
            "tenant_id": entry.tenant_id,
            "natural_language_query": entry.natural_language_query,
            "generated_sql": entry.generated_sql,
            "validation_result": entry.validation_result,
            "rejection_reasons": entry.rejection_reasons,
            "execution_result": entry.execution_result,
            "row_count": entry.row_count,
            "duration_ms": entry.duration_ms,
        }

        # Structured log (picked up by Application Insights exporter)
        self._logger.info("query_audit", **log_data)

        # NDJSON file (append-only)
        log_file = self._log_dir / f"audit-{entry.timestamp.strftime('%Y-%m-%d')}.ndjson"
        async with aiofiles.open(log_file, mode="a") as f:
            await f.write(json.dumps(log_data) + "\n")
```

#### 6.8.3 Dependency Summary

Add to `backend/requirements.txt`:

```
sqlglot>=26.0
sqlalchemy[asyncio]>=2.0
aioodbc>=0.5
structlog>=24.0
aiofiles>=24.0
azure-keyvault-secrets>=4.8
azure-identity>=1.17
azure-monitor-opentelemetry>=1.6
```

---

### 6.9 Security Invariants Summary

These invariants must hold at all times. Any violation is a critical bug.

| # | Invariant | Verification |
|---|-----------|--------------|
| 1 | No agent class imports `sqlalchemy`, `pyodbc`, or `aioodbc` | CI lint rule + code review |
| 2 | `DataAccessLayer.execute()` accepts only `ValidatedQuery` — never `str` | Type checker (mypy strict) |
| 3 | Connection strings are never logged, serialized, or returned in API responses | grep CI check for connection string patterns |
| 4 | Tenant ID for connection resolution comes exclusively from JWT claims | Code review + integration test |
| 5 | Every code path that reaches the database passes through `SQLValidator.validate()` | Architecture test (no direct `engine.execute()` outside DAL) |
| 6 | `SELECT *` is never executed | SQL Validator AST check |
| 7 | Rejected queries are never executed | `ValidatedQuery` is only constructable by `SQLValidator` |
| 8 | Raw SQL errors are never included in HTTP responses | Response model validation (no `error_detail` field in API schema) |
