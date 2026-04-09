from __future__ import annotations

import logging
from typing import Any

from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.pool import QueuePool, StaticPool

from app.config import get_settings

logger = logging.getLogger(__name__)

_engines: dict[str, Engine] = {}

VALID_CUSTOMER_DBS = {"acme", "nova", "apex"}


def _build_connection_string(customer_db: str) -> str:
    """Build a SQLAlchemy connection string for the given customer DB key."""
    settings = get_settings()
    server = settings.azure_sql_server
    prefix = settings.azure_sql_database_prefix
    user = settings.azure_sql_user
    password = settings.azure_sql_password
    db_name = f"{prefix}-{customer_db}" if prefix else customer_db
    return (
        f"mssql+pyodbc://{user}:{password}@{server}/{db_name}"
        f"?driver=ODBC+Driver+18+for+SQL+Server"
    )


def _build_engine(customer_db: str) -> Engine:
    """Create a SQLAlchemy engine for the given customer database."""
    settings = get_settings()

    if settings.use_local_sqlite:
        import os
        db_dir = os.path.join(os.path.dirname(__file__), "..", "..", "data")
        os.makedirs(db_dir, exist_ok=True)
        db_path = os.path.join(db_dir, f"{customer_db}.db")
        return create_engine(
            f"sqlite:///{db_path}",
            poolclass=StaticPool,
            connect_args={"check_same_thread": False},
        )

    connection_string = _build_connection_string(customer_db)
    return create_engine(
        connection_string,
        poolclass=QueuePool,
        pool_size=5,
        max_overflow=10,
        pool_timeout=30,
        pool_pre_ping=True,
    )


def get_available_databases() -> list[str]:
    """Return the list of valid customer database keys."""
    return sorted(VALID_CUSTOMER_DBS)


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
        _engines[customer_db] = _build_engine(customer_db)
        logger.info("Created engine for customer DB '%s'.", customer_db)

    return _engines[customer_db]


def execute_query(customer_db: str, sql: str, timeout: int | None = None) -> list[dict[str, Any]]:
    """Execute a SELECT query against the specified customer database.

    Args:
        customer_db: One of 'acme', 'nova', 'apex'.
        sql: A validated SELECT statement.
        timeout: Per-query timeout in seconds. Falls back to ``query_timeout_seconds``.

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
            if not settings.use_local_sqlite:
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
