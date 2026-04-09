from __future__ import annotations

import logging
from typing import Any

from sqlalchemy import create_engine, text, event
from sqlalchemy.engine import Engine
from sqlalchemy.pool import QueuePool

from app.config import get_settings

logger = logging.getLogger(__name__)

_engines: dict[str, Engine] = {}

VALID_CUSTOMER_DBS = {"acme", "nova", "apex"}


def _build_engine(connection_string: str) -> Engine:
    """Create a SQLAlchemy engine with sensible pool settings."""
    return create_engine(
        connection_string,
        poolclass=QueuePool,
        pool_size=5,
        max_overflow=10,
        pool_timeout=30,
        pool_pre_ping=True,
        connect_args={"timeout": 30},
    )


def get_engine(customer_db: str) -> Engine:
    """Return (and cache) the SQLAlchemy engine for the given customer key.

    Args:
        customer_db: One of 'acme', 'nova', 'apex'.

    Raises:
        ValueError: If ``customer_db`` is not a recognised key.
    """
    if customer_db not in VALID_CUSTOMER_DBS:
        raise ValueError(f"Unknown customer database: '{customer_db}'. Must be one of {VALID_CUSTOMER_DBS}.")

    if customer_db not in _engines:
        settings = get_settings()
        conn_map: dict[str, str] = {
            "acme": settings.db_acme_connection_string,
            "nova": settings.db_nova_connection_string,
            "apex": settings.db_apex_connection_string,
        }
        _engines[customer_db] = _build_engine(conn_map[customer_db])
        logger.info("Created engine for customer DB '%s'.", customer_db)

    return _engines[customer_db]


def execute_query(customer_db: str, sql: str, timeout: int | None = None) -> list[dict[str, Any]]:
    """Execute a SELECT query against the specified customer database.

    Args:
        customer_db: One of 'acme', 'nova', 'apex'.
        sql: A validated SELECT statement.
        timeout: Per-query timeout in seconds. Falls back to ``QUERY_TIMEOUT_SECONDS``.

    Returns:
        A list of row dicts (column_name → value).

    Raises:
        ValueError: On invalid ``customer_db``.
        RuntimeError: On connection or query execution failure.
    """
    settings = get_settings()
    effective_timeout = timeout if timeout is not None else settings.query_timeout_seconds

    try:
        engine = get_engine(customer_db)
        with engine.connect() as conn:
            # Set a per-session statement timeout for Azure SQL
            conn.execute(text(f"SET LOCK_TIMEOUT {effective_timeout * 1000}"))
            result = conn.execute(text(sql))
            keys = list(result.keys())
            rows = [dict(zip(keys, row)) for row in result.fetchall()]
            return rows
    except ValueError:
        raise
    except Exception as exc:
        logger.exception("Query execution failed on '%s': %s", customer_db, exc)
        raise RuntimeError(f"Database query failed: {exc}") from exc
