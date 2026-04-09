"""
Audit Logger
============
Emits structured, compliance-grade audit events for every query attempt.

Security rationale:
  - All access attempts (allowed *and* rejected) must be logged so that
    security teams can detect anomalous behaviour, replay incidents, and
    satisfy compliance requirements.
  - The *actual* SQL and question text are **never** logged — they may contain
    PII or sensitive schema information.  Only metadata (lengths, booleans,
    risk levels) is recorded.
  - Logs are emitted to stdout as newline-delimited JSON (NDJSON) so they can
    be captured by any container logging infrastructure.
  - If ``APPINSIGHTS_CONNECTION_STRING`` is set, events are also forwarded to
    Azure Application Insights via ``opencensus-ext-azure``.
"""

from __future__ import annotations

import json
import logging
import os
from datetime import datetime, timezone
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.guardrails.sql_validator import SQLValidationResult
    from app.guardrails.prompt_safety import PromptSafetyResult

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# App Insights setup (optional — only when the env-var is present)
# ---------------------------------------------------------------------------

_ai_logger: logging.Logger | None = None

_APPINSIGHTS_CONN_STR = os.environ.get("APPINSIGHTS_CONNECTION_STRING", "")

if _APPINSIGHTS_CONN_STR:
    try:
        from opencensus.ext.azure.log_exporter import AzureLogHandler

        _ai_logger = logging.getLogger("audit.appinsights")
        _ai_logger.setLevel(logging.INFO)
        _ai_logger.addHandler(
            AzureLogHandler(connection_string=_APPINSIGHTS_CONN_STR)
        )
        logger.info("Azure Application Insights audit sink initialised.")
    except ImportError:
        logger.warning(
            "APPINSIGHTS_CONNECTION_STRING is set but 'opencensus-ext-azure' "
            "is not installed — App Insights logging is disabled."
        )


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def log_query_event(
    user_email: str,
    customer_db: str,
    user_question: str,
    generated_sql: str | None,
    validation_result: "SQLValidationResult | None",
    prompt_safety_result: "PromptSafetyResult | None",
    execution_success: bool,
    row_count: int | None,
    error: str | None,
    duration_ms: float,
) -> None:
    """Emit a structured audit event for a single query lifecycle.

    Intentionally omits the raw SQL and question text to avoid logging PII
    or sensitive schema information.  Lengths are recorded as proxies for
    anomaly detection (e.g. unusually long queries may indicate injection).

    Args:
        user_email:           Authenticated user's email (from JWT).
        customer_db:          Target customer database key.
        user_question:        Raw natural-language question (length logged only).
        generated_sql:        AI-generated SQL string (length logged only).
        validation_result:    Result from :func:`validate_sql`, or None if SQL
                              was never generated.
        prompt_safety_result: Result from :func:`check_prompt_safety`, or None.
        execution_success:    Whether the SQL was executed successfully.
        row_count:            Number of rows returned, if execution succeeded.
        error:                Error message if execution failed; None otherwise.
        duration_ms:          Total request duration in milliseconds.
    """
    # Derive summary fields from result objects — safe to include.
    sql_valid: bool | None = (
        validation_result.is_valid if validation_result is not None else None
    )
    prompt_safe: bool | None = (
        prompt_safety_result.is_safe if prompt_safety_result is not None else None
    )

    # Use the highest risk level across both checks.
    risk_level = _highest_risk(
        validation_result.risk_level if validation_result else "none",
        prompt_safety_result.risk_level if prompt_safety_result else "none",
    )

    event: dict = {
        "event": "query_attempt",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "user": user_email,
        "customer_db": customer_db,
        # Lengths only — never the actual content.
        "question_length": len(user_question),
        "sql_length": len(generated_sql) if generated_sql is not None else None,
        "sql_generated": generated_sql is not None,
        "sql_valid": sql_valid,
        "prompt_safe": prompt_safe,
        "risk_level": risk_level,
        "execution_success": execution_success,
        "row_count": row_count,
        "duration_ms": duration_ms,
        # Error string is low-sensitivity (no data, just a failure code/type).
        "error": error,
    }

    # Always write to stdout as NDJSON.
    print(json.dumps(event, default=str))  # noqa: T201

    # Optionally forward to Azure App Insights.
    if _ai_logger is not None:
        _ai_logger.info(
            "query_attempt",
            extra={"custom_dimensions": event},
        )


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

_RISK_ORDER: dict[str, int] = {
    "none": 0,
    "low": 1,
    "medium": 2,
    "high": 3,
    "critical": 4,
}


def _highest_risk(a: str, b: str) -> str:
    """Return whichever of *a* or *b* is the higher risk level."""
    return a if _RISK_ORDER.get(a, 0) >= _RISK_ORDER.get(b, 0) else b
