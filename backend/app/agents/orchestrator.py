import time
import structlog
from app.auth.validator import AuthContext
from app.agents.prompt_safety import check_prompt_safety
from app.agents.schema_context import get_schema_context
from app.agents.sql_generator import generate_sql
from app.agents.sql_validator import validate_sql
from app.agents.response_formatter import format_response
from app.db.data_access import execute_validated_query
from app.observability.audit_logger import AuditLogger

logger = structlog.get_logger(__name__)


async def orchestrate_query(
    question: str,
    database: str,
    auth_context: AuthContext,
    audit_logger: AuditLogger,
) -> dict:
    """
    Explicit pipeline orchestration — no LLM routing.
    Steps: Safety → Schema → SQL Gen → Validation → Execution → Formatting
    On rejection at any step, return user-friendly error.
    SQL Generator → Validator loop allows max 2 retries.
    """
    request_id = auth_context.request_id
    start_time = time.monotonic()

    # Step 1: Prompt Safety Check
    safety_result = await check_prompt_safety(question, auth_context)
    await audit_logger.log_event(
        "prompt_safety", request_id, auth_context, safety_result
    )
    if not safety_result["is_safe"]:
        return {
            "success": False,
            "message": "I can't process that request. Please rephrase your question about your data.",
            "request_id": request_id,
        }

    # Step 2: Schema Context
    schema_context = await get_schema_context(question, database)
    if not schema_context["relevant_tables"]:
        return {
            "success": False,
            "message": "I couldn't find relevant data tables for your question. Could you rephrase?",
            "request_id": request_id,
        }

    # Step 3 & 4: SQL Generation + Validation (with retry loop)
    max_retries = 2
    feedback = None
    for attempt in range(max_retries + 1):
        sql_result = await generate_sql(question, schema_context, database, feedback)
        await audit_logger.log_event(
            "sql_generation",
            request_id,
            auth_context,
            {"sql": sql_result["sql"], "attempt": attempt},
        )

        validation = validate_sql(
            sql_result["sql"],
            database,
            schema_context["allowed_tables"],
            schema_context["allowed_columns"],
        )
        await audit_logger.log_event(
            "sql_validation",
            request_id,
            auth_context,
            {
                "valid": validation["is_valid"],
                "violations": validation.get("violations", []),
            },
        )

        if validation["is_valid"]:
            break
        feedback = validation["violations"]
    else:
        return {
            "success": False,
            "message": "I couldn't generate a safe query for that request. Could you try asking in a different way?",
            "request_id": request_id,
        }

    # Step 5: Execute
    try:
        exec_result = await execute_validated_query(
            validation["sanitized_sql"], database, request_id
        )
        await audit_logger.log_event(
            "sql_execution",
            request_id,
            auth_context,
            {
                "row_count": exec_result["row_count"],
                "duration_ms": exec_result["execution_time_ms"],
            },
        )
    except Exception as e:
        logger.error("sql_execution_error", request_id=request_id, error=str(e))
        await audit_logger.log_event(
            "sql_execution_error",
            request_id,
            auth_context,
            {"error": str(e)},
        )
        return {
            "success": False,
            "message": "There was an issue retrieving the data. Please try again.",
            "request_id": request_id,
        }

    # Step 6: Format Response
    formatted = await format_response(question, exec_result)

    total_ms = int((time.monotonic() - start_time) * 1000)

    return {
        "success": True,
        "answer": formatted["answer"],
        "sql": validation["sanitized_sql"],
        "columns": exec_result["columns"],
        "rows": exec_result["rows"],
        "row_count": exec_result["row_count"],
        "execution_time_ms": total_ms,
        "request_id": request_id,
    }
