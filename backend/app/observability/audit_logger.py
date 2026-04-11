import structlog

logger = structlog.get_logger("audit")


class AuditLogger:
    def log_query_attempt(
        self,
        user_email: str,
        database: str,
        query: str,
        approved: bool,
        reason: str,
    ) -> None:
        logger.info(
            "query_attempt",
            user=user_email,
            database=database,
            query=query,
            verdict="approved" if approved else "rejected",
            reason=reason,
        )
