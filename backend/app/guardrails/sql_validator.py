"""
SQL Guardrail Validator
=======================
Validates AI-generated SQL before execution against Azure SQL databases.

Security rationale:
  An AI model can be tricked (via prompt injection or adversarial inputs) into
  generating malicious SQL.  This module acts as a last-line-of-defence,
  parsing and rejecting any SQL that is not a safe, single-statement SELECT
  before it ever reaches the database driver.

All validation is purely in-memory — no DB or network calls.
"""

from __future__ import annotations

import re
from dataclasses import dataclass

import sqlparse
from sqlparse.sql import Statement
from sqlparse.tokens import Keyword, DDL, DML

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

MAX_QUERY_LENGTH: int = 2000

# Keywords whose mere presence indicates a non-SELECT statement type.
_DDL_BLOCKLIST: frozenset[str] = frozenset(
    {"DROP", "CREATE", "ALTER", "TRUNCATE", "RENAME"}
)

_DML_BLOCKLIST: frozenset[str] = frozenset(
    {"INSERT", "UPDATE", "DELETE", "MERGE", "UPSERT"}
)

# Dangerous stored procedures and built-ins used for OS access / data
# exfiltration / dynamic SQL execution on SQL Server.
_DANGEROUS_FUNCTIONS: tuple[str, ...] = (
    "xp_cmdshell",
    "sp_executesql",
    r"\bEXEC\b",
    r"\bEXECUTE\b",
    "OPENROWSET",
    "OPENDATASOURCE",
    "OPENQUERY",
    r"BULK\s+INSERT",
    r"\bbcp\b",
)

# Prefixes that indicate access to SQL Server internal / system metadata
# tables.  Allowing an AI to read these would expose schema details usable
# for further attacks.
_SYSTEM_TABLE_PATTERNS: tuple[str, ...] = (
    r"\bsys\.",
    r"\binformation_schema\.",
    r"\bmaster\.",
    r"\bmsdb\.",
    r"\btempdb\.",
)

# Pre-compiled regexes for performance.
_RE_DANGEROUS = re.compile(
    "|".join(_DANGEROUS_FUNCTIONS), re.IGNORECASE
)
_RE_SYSTEM_TABLES = re.compile(
    "|".join(_SYSTEM_TABLE_PATTERNS), re.IGNORECASE
)
_RE_UNION = re.compile(r"\bUNION\b", re.IGNORECASE)


# ---------------------------------------------------------------------------
# Result model
# ---------------------------------------------------------------------------


@dataclass
class SQLValidationResult:
    """Outcome of a SQL validation check.

    Attributes:
        is_valid:   Whether the SQL may proceed to execution.
        reason:     Human-readable rejection reason; None when valid.
        risk_level: One of "none", "low", "medium", "high", "critical".
    """

    is_valid: bool
    reason: str | None
    risk_level: str


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def validate_sql(sql: str) -> SQLValidationResult:
    """Validate AI-generated SQL before execution.

    Runs a series of fail-fast checks (ordered from cheapest to most
    expensive) and returns a :class:`SQLValidationResult`.

    Args:
        sql: The raw SQL string produced by the AI model.

    Returns:
        A :class:`SQLValidationResult` describing whether the query is
        safe to execute.
    """
    # ------------------------------------------------------------------
    # 1. Length check
    # Extremely long queries are unusual for legitimate analytics and are
    # a common carrier for obfuscated injection payloads.
    # ------------------------------------------------------------------
    if len(sql) > MAX_QUERY_LENGTH:
        return SQLValidationResult(
            is_valid=False,
            reason=(
                f"Query exceeds maximum allowed length of "
                f"{MAX_QUERY_LENGTH} characters."
            ),
            risk_level="critical",
        )

    # ------------------------------------------------------------------
    # 2. Comment injection
    # SQL comments (`--` and `/* */`) are routinely used to truncate the
    # remainder of a query or hide injected code from naive filters.
    # Legitimate AI-generated SELECT queries have no reason to contain
    # comments, so we reject all of them unconditionally.
    # ------------------------------------------------------------------
    if "--" in sql or "/*" in sql:
        return SQLValidationResult(
            is_valid=False,
            reason=(
                "SQL comments (-- or /*) are not permitted; they may "
                "be used to hide injection payloads."
            ),
            risk_level="critical",
        )

    # ------------------------------------------------------------------
    # 3. Parse with sqlparse
    # ------------------------------------------------------------------
    statements = sqlparse.parse(sql.strip())

    # ------------------------------------------------------------------
    # 4. Single statement only
    # Multiple statements separated by `;` (query stacking) allow an
    # attacker to append arbitrary DDL/DML after a valid SELECT.
    # ------------------------------------------------------------------
    non_empty = [s for s in statements if s.value.strip()]
    if len(non_empty) != 1:
        return SQLValidationResult(
            is_valid=False,
            reason=(
                f"Expected exactly 1 SQL statement; found {len(non_empty)}. "
                "Query stacking is not permitted."
            ),
            risk_level="critical",
        )

    statement: Statement = non_empty[0]

    # ------------------------------------------------------------------
    # 5. Statement type must be SELECT
    # We only allow read-only queries.  sqlparse.get_type() returns the
    # upper-cased keyword of the first meaningful token.
    # ------------------------------------------------------------------
    stmt_type = statement.get_type()
    if stmt_type != "SELECT":
        return SQLValidationResult(
            is_valid=False,
            reason=(
                f"Only SELECT statements are permitted; "
                f"got '{stmt_type or 'UNKNOWN'}'."
            ),
            risk_level="critical",
        )

    # ------------------------------------------------------------------
    # 6. Keyword blocklist (DDL + DML) — token-level scan
    # sqlparse classifies tokens by type, so we check both DDL and DML
    # token categories as well as generic Keyword tokens.  This catches
    # cases like `SELECT 1; DROP TABLE …` that slip past the type check.
    # ------------------------------------------------------------------
    for token in statement.flatten():
        upper_val = token.normalized.upper()
        if token.ttype in (DDL, DML):
            # SELECT itself carries the DML token type — that's what we want.
            # Block every other DML/DDL keyword found in the token stream.
            if upper_val == "SELECT":
                continue
            return SQLValidationResult(
                is_valid=False,
                reason=(
                    f"Forbidden keyword '{upper_val}' detected (DDL/DML "
                    "modification is not allowed)."
                ),
                risk_level="critical",
            )
        if token.ttype is Keyword and upper_val in (
            _DDL_BLOCKLIST | _DML_BLOCKLIST
        ):
            return SQLValidationResult(
                is_valid=False,
                reason=(
                    f"Forbidden keyword '{upper_val}' detected."
                ),
                risk_level="critical",
            )

    # Work with an upper-cased string for the remaining regex checks so
    # we don't have to repeat re.IGNORECASE everywhere.
    sql_upper = sql.upper()

    # ------------------------------------------------------------------
    # 7. Dangerous function / stored procedure blocklist
    # These SQL Server functions can execute OS commands, open remote
    # connections, or run arbitrary dynamic SQL.
    # ------------------------------------------------------------------
    match = _RE_DANGEROUS.search(sql_upper)
    if match:
        return SQLValidationResult(
            is_valid=False,
            reason=(
                f"Dangerous function or procedure detected: "
                f"'{match.group()}'. Execution helpers are not permitted."
            ),
            risk_level="critical",
        )

    # ------------------------------------------------------------------
    # 8. System / internal table access
    # Querying sys.* or information_schema.* leaks schema information
    # that attackers can use to map the database for further exploitation.
    # ------------------------------------------------------------------
    match = _RE_SYSTEM_TABLES.search(sql)
    if match:
        return SQLValidationResult(
            is_valid=False,
            reason=(
                f"Access to system or internal tables is not permitted "
                f"(matched: '{match.group()}')."
            ),
            risk_level="critical",
        )

    # ------------------------------------------------------------------
    # 9. UNION detection — allow but flag as low risk
    # UNION SELECT is legitimate for some analytics queries, but is also
    # the basis of UNION-based SQL injection.  We allow it while flagging
    # it so downstream monitoring can alert on unusual patterns.
    # ------------------------------------------------------------------
    if _RE_UNION.search(sql):
        return SQLValidationResult(
            is_valid=True,
            reason=None,
            risk_level="low",
        )

    # ------------------------------------------------------------------
    # All checks passed — query is clean.
    # ------------------------------------------------------------------
    return SQLValidationResult(is_valid=True, reason=None, risk_level="none")
