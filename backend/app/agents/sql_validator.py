import re
import sqlglot
from sqlglot import exp
import structlog

logger = structlog.get_logger(__name__)

BLOCKED_KEYWORDS = [
    "INSERT", "UPDATE", "DELETE", "DROP", "ALTER", "EXEC", "EXECUTE",
    "TRUNCATE", "MERGE", "CREATE", "GRANT", "REVOKE", "BACKUP", "RESTORE",
    "BULK", "RECONFIGURE", "OPENROWSET", "OPENQUERY", "OPENDATASOURCE",
    "XP_", "SP_EXECUTESQL", "INTO",
]

BLOCKED_PATTERNS = [
    r"sys\.\w+",
    r"INFORMATION_SCHEMA\.\w+",
    r"EXEC\s*\(",
    r"sp_executesql",
    r"EXECUTE\s+\(",
    r"--",
    r"/\*",
    r"\bGO\b",
    r"DECLARE\s+@",
    r"SET\s+@",
    r"WAITFOR\b",
    r"\bUSE\s+\w+",
]

MAX_JOINS = 4
MAX_ROWS = 500


def validate_sql(
    sql: str,
    tenant_db: str,
    allowed_tables: set[str],
    allowed_columns: dict[str, set[str]],
) -> dict:
    """Validate generated SQL against security rules. Returns validation result."""
    if not sql or not sql.strip():
        return {"is_valid": False, "violations": ["EMPTY_SQL: No SQL provided"], "sanitized_sql": None}

    violations = []

    # 1. Blocked keyword scan (case-insensitive)
    sql_upper = sql.upper()
    for keyword in BLOCKED_KEYWORDS:
        # Use word boundary to avoid false positives
        if re.search(rf"\b{keyword}\b", sql_upper):
            violations.append(f"BLOCKED_KEYWORD: {keyword}")

    # 2. Blocked pattern scan
    for pattern in BLOCKED_PATTERNS:
        if re.search(pattern, sql, re.IGNORECASE):
            violations.append(f"BLOCKED_PATTERN: matched {pattern}")

    # 3. Parse AST
    try:
        statements = sqlglot.parse(sql, dialect="tsql")
    except sqlglot.errors.ParseError as e:
        return {"is_valid": False, "violations": [f"PARSE_ERROR: {e}"], "sanitized_sql": None}

    # 4. Must be exactly one statement
    if len(statements) != 1:
        violations.append(f"MULTI_STATEMENT: {len(statements)} statements found, only 1 allowed")
        if violations:
            return {"is_valid": False, "violations": violations, "sanitized_sql": None}

    stmt = statements[0]

    # 5. Must be SELECT
    if not isinstance(stmt, exp.Select):
        violations.append(f"NOT_SELECT: Statement type is {type(stmt).__name__}")

    # 6. Check table references
    for table in stmt.find_all(exp.Table):
        table_name = table.name.lower()
        # Check for cross-database references (3-part names)
        if table.db:
            violations.append(f"CROSS_DATABASE: {table.db}.{table_name}")
        if table.catalog:
            violations.append(f"LINKED_SERVER: {table.catalog}.{table.db}.{table_name}")
        if table_name and table_name not in allowed_tables:
            violations.append(f"UNAUTHORIZED_TABLE: {table_name}")

    # 7. Check column references (if we can resolve the table)
    for col in stmt.find_all(exp.Column):
        if col.table:
            table_lower = col.table.lower()
            col_lower = col.name.lower()
            if table_lower in allowed_columns and col_lower not in allowed_columns[table_lower]:
                violations.append(f"UNAUTHORIZED_COLUMN: {table_lower}.{col_lower}")

    # 8. Check JOIN count
    join_count = len(list(stmt.find_all(exp.Join)))
    if join_count > MAX_JOINS:
        violations.append(f"TOO_MANY_JOINS: {join_count} joins (max {MAX_JOINS})")

    # 9. Check for SELECT *
    for star in stmt.find_all(exp.Star):
        violations.append("SELECT_STAR: Use explicit column list instead of *")
        break

    if violations:
        return {"is_valid": False, "violations": violations, "sanitized_sql": None}

    # 10. Inject TOP if not present
    sanitized = sql
    if "TOP" not in sql_upper and "LIMIT" not in sql_upper:
        # Inject TOP 500 after SELECT
        sanitized = re.sub(r"(?i)^SELECT\s", f"SELECT TOP {MAX_ROWS} ", sanitized, count=1)

    # 11. Strip comments if any slipped through
    sanitized = re.sub(r"--.*$", "", sanitized, flags=re.MULTILINE)
    sanitized = re.sub(r"/\*.*?\*/", "", sanitized, flags=re.DOTALL)

    return {"is_valid": True, "violations": [], "sanitized_sql": sanitized.strip()}
