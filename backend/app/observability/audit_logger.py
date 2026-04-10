import json
import os
from datetime import datetime, timezone
from pathlib import Path
import aiofiles
import structlog
from app.auth.validator import AuthContext

logger = structlog.get_logger("audit")


class AuditLogger:
    def __init__(self, log_dir: str = "./audit_logs"):
        self._log_dir = Path(log_dir)
        self._log_dir.mkdir(parents=True, exist_ok=True)
    
    async def log_event(
        self,
        event_type: str,
        request_id: str,
        auth_context: AuthContext,
        details: dict,
    ) -> None:
        entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "request_id": request_id,
            "event_type": event_type,
            "user_id": auth_context.user_id,
            "tenant_id": auth_context.tenant_id,
            "username": auth_context.username,
            "details": details,
        }
        
        # Structured log (picked up by Application Insights if configured)
        logger.info("audit_event", **entry)
        
        # NDJSON file (append-only)
        today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        log_file = self._log_dir / f"audit-{today}.ndjson"
        try:
            async with aiofiles.open(str(log_file), mode="a") as f:
                await f.write(json.dumps(entry, default=str) + "\n")
        except Exception as e:
            logger.error("audit_write_failed", error=str(e))
    
    async def log_query(
        self,
        request_id: str,
        auth_context: AuthContext,
        question: str,
        generated_sql: str | None,
        validation_result: str,
        rejection_reasons: list[str],
        execution_result: str | None,
        row_count: int | None,
        duration_ms: int,
    ) -> None:
        await self.log_event("query_lifecycle", request_id, auth_context, {
            "question": question,
            "generated_sql": generated_sql,
            "validation_result": validation_result,
            "rejection_reasons": rejection_reasons,
            "execution_result": execution_result,
            "row_count": row_count,
            "duration_ms": duration_ms,
        })
