# Security Model

## Authentication

- Custom email/password authentication (NOT Microsoft Entra ID / MSAL)
- Passwords hashed with bcrypt, never stored in plain text
- Password policy: minimum 8 characters, at least 1 uppercase, 1 lowercase, 1 number
- JWT tokens signed with HS256 algorithm
  - Access token TTL: 15 minutes
  - Refresh token TTL: 7 days
  - Claims: `sub` (user_id), `email`, `domain` (extracted from email), `exp`, `iat`
- Tokens stored in browser memory (React state/context) — never in localStorage or sessionStorage

## Authorization — Tenant Isolation

### Domain-Based Database Access
Users are mapped to databases by their email domain via the `DomainDatabaseMap` table in `db-users`:

| Domain | Databases |
|--------|-----------|
| acme.com | db-acme |
| nova.com | db-nova |
| apex.com | db-apex |
| inriver.com | db-acme, db-nova, db-apex (admin) |

### Enforcement Layers

1. **JWT Domain Extraction**: The backend extracts the email domain from the authenticated JWT on every request
2. **Server-Side Resolution**: The `DomainResolver` maps the domain to authorized database(s) — the frontend never selects a database
3. **Request Validation**: Every query request validates that the target database is in the user's authorized list
4. **Connection Scoping**: The `TenantConnectionManager` only creates connections to authorized databases

### What the Frontend CANNOT Do
- Select or specify which database to query
- See databases outside its authorized scope
- Override server-side authorization

## SQL Security

### AST-Level Validation (sqlglot)
- All SQL is parsed into an AST using `sqlglot` — no regex-based validation
- Only `SELECT` statements are allowed
- Explicitly rejected: `INSERT`, `UPDATE`, `DELETE`, `DROP`, `ALTER`, `EXEC`, `EXECUTE`, `TRUNCATE`, `CREATE`
- Multiple statements (semicolon-separated) are rejected
- Subqueries, CTEs, and JOINs are allowed within SELECT

### Audit Logging
- Every query attempt is logged via structlog in NDJSON format
- Logged fields: timestamp, user_email, database, query, approved (bool), reason
- Both approved AND rejected queries are logged

### Data Access Layer
- The DAL is the sole component that executes SQL against tenant databases
- Uses `aioodbc`/`pyodbc` with Azure AD token authentication in production
- Mock fallback available for local development
