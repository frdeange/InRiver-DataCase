from __future__ import annotations

import logging
import os
import sqlite3
from pathlib import Path
from typing import Any

from app.auth.rbac import VALID_DATABASES
from app.config import get_settings

logger = logging.getLogger(__name__)

_DATA_DIR = Path(__file__).parent.parent.parent / "data"

# Minimal SQLite-compatible schema for local dev (mirrors InRiver PIM tables)
_SQLITE_SCHEMA = """
CREATE TABLE IF NOT EXISTS Languages (
    language_id   INTEGER PRIMARY KEY,
    language_code TEXT NOT NULL,
    language_name TEXT NOT NULL,
    is_default    INTEGER DEFAULT 0,
    created_at    TEXT,
    updated_at    TEXT
);

CREATE TABLE IF NOT EXISTS Channels (
    channel_id   INTEGER PRIMARY KEY,
    channel_code TEXT NOT NULL,
    channel_name TEXT NOT NULL,
    is_active    INTEGER DEFAULT 1,
    created_at   TEXT,
    updated_at   TEXT
);

CREATE TABLE IF NOT EXISTS Categories (
    category_id   INTEGER PRIMARY KEY,
    parent_id     INTEGER,
    category_code TEXT NOT NULL,
    category_name TEXT NOT NULL,
    sort_order    INTEGER DEFAULT 0,
    created_at    TEXT,
    updated_at    TEXT
);

CREATE TABLE IF NOT EXISTS Products (
    product_id   INTEGER PRIMARY KEY,
    sku          TEXT NOT NULL UNIQUE,
    product_name TEXT NOT NULL,
    brand        TEXT,
    status       TEXT DEFAULT 'active',
    created_at   TEXT,
    updated_at   TEXT
);

CREATE TABLE IF NOT EXISTS ProductCategories (
    product_id  INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    is_primary  INTEGER DEFAULT 0,
    PRIMARY KEY (product_id, category_id)
);

CREATE TABLE IF NOT EXISTS Attributes (
    attribute_id   INTEGER PRIMARY KEY,
    attribute_code TEXT NOT NULL UNIQUE,
    attribute_name TEXT NOT NULL,
    data_type      TEXT NOT NULL,
    unit           TEXT,
    is_localizable INTEGER DEFAULT 0,
    is_required    INTEGER DEFAULT 0,
    created_at     TEXT,
    updated_at     TEXT
);

CREATE TABLE IF NOT EXISTS ProductAttributeValues (
    value_id     INTEGER PRIMARY KEY,
    product_id   INTEGER NOT NULL,
    attribute_id INTEGER NOT NULL,
    language_id  INTEGER,
    text_value   TEXT,
    number_value REAL,
    bool_value   INTEGER,
    date_value   TEXT,
    created_at   TEXT,
    updated_at   TEXT
);

CREATE TABLE IF NOT EXISTS ProductChannels (
    product_id   INTEGER NOT NULL,
    channel_id   INTEGER NOT NULL,
    is_published INTEGER DEFAULT 0,
    published_at TEXT,
    PRIMARY KEY (product_id, channel_id)
);

CREATE TABLE IF NOT EXISTS MediaAssets (
    asset_id    INTEGER PRIMARY KEY,
    product_id  INTEGER NOT NULL,
    asset_type  TEXT NOT NULL,
    file_name   TEXT,
    url         TEXT,
    alt_text    TEXT,
    sort_order  INTEGER DEFAULT 0,
    language_id INTEGER,
    created_at  TEXT,
    updated_at  TEXT
);
"""

_SQLITE_SEED = """
INSERT OR IGNORE INTO Languages (language_id, language_code, language_name, is_default)
    VALUES (1, 'en', 'English', 1);

INSERT OR IGNORE INTO Categories (category_id, parent_id, category_code, category_name)
    VALUES (1, NULL, 'electronics', 'Electronics'),
           (2, 1,    'laptops',     'Laptops'),
           (3, 1,    'phones',      'Phones');

INSERT OR IGNORE INTO Products (product_id, sku, product_name, brand, status)
    VALUES (1, 'LAP-001', 'ProBook 450', 'HP',   'active'),
           (2, 'PHN-001', 'Galaxy S24',  'Samsung', 'active'),
           (3, 'LAP-002', 'MacBook Air', 'Apple', 'active');

INSERT OR IGNORE INTO ProductCategories (product_id, category_id, is_primary)
    VALUES (1, 2, 1), (2, 3, 1), (3, 2, 1);
"""


def init_sqlite_db(customer: str) -> None:
    """Create the SQLite database file with a minimal schema if it doesn't exist."""
    _DATA_DIR.mkdir(parents=True, exist_ok=True)
    db_path = _DATA_DIR / f"{customer}.db"
    conn = sqlite3.connect(str(db_path))
    try:
        conn.executescript(_SQLITE_SCHEMA)
        conn.executescript(_SQLITE_SEED)
        conn.commit()
        logger.info("SQLite DB initialised for customer '%s' at %s", customer, db_path)
    finally:
        conn.close()


def _sqlite_execute(customer: str, sql: str) -> list[dict[str, Any]]:
    """Run a SELECT against the local SQLite dev database."""
    db_path = _DATA_DIR / f"{customer}.db"
    if not db_path.exists():
        init_sqlite_db(customer)

    # Translate simple T-SQL TOP N → SQLite LIMIT N for dev convenience
    import re
    sql = re.sub(r"(?i)\bSELECT\s+TOP\s+(\d+)\b", r"SELECT", sql, count=1)
    top_match = re.search(r"(?i)\bSELECT\s+TOP\s+(\d+)\b", sql)
    limit_clause = ""
    if top_match:
        limit_clause = f" LIMIT {top_match.group(1)}"
        sql = re.sub(r"(?i)\bSELECT\s+TOP\s+(\d+)\b", "SELECT", sql, count=1)

    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    try:
        cursor = conn.execute(sql + limit_clause)
        rows = [dict(row) for row in cursor.fetchmany(500)]
        return rows
    finally:
        conn.close()


def _pyodbc_execute(customer: str, sql: str) -> list[dict[str, Any]]:
    """Run a SELECT against Azure SQL via pyodbc."""
    import pyodbc

    settings = get_settings()
    conn_str = (
        f"Driver={{ODBC Driver 18 for SQL Server}};"
        f"Server={settings.azure_sql_server};"
        f"Database={settings.azure_sql_database_prefix}-{customer};"
        f"UID={settings.azure_sql_user};"
        f"PWD={settings.azure_sql_password};"
        f"Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30"
    )
    conn = pyodbc.connect(conn_str, timeout=settings.query_timeout_seconds)
    try:
        cursor = conn.cursor()
        cursor.execute(sql)
        columns = [col[0] for col in cursor.description]
        rows = []
        for row in cursor.fetchmany(500):
            rows.append(dict(zip(columns, row)))
        return rows
    finally:
        conn.close()


def execute_query(customer_db: str, sql: str) -> list[dict[str, Any]]:
    """Execute a validated SELECT query against the given customer database.

    Args:
        customer_db: Customer key — must be one of VALID_DATABASES.
        sql:         A pre-validated SELECT statement.

    Returns:
        List of row dicts (up to 500 rows).

    Raises:
        PermissionError: If customer_db is not in VALID_DATABASES.
        RuntimeError:    On connection or execution failure.
    """
    if customer_db not in VALID_DATABASES:
        raise PermissionError(f"Database '{customer_db}' is not accessible.")

    settings = get_settings()
    try:
        if settings.use_local_sqlite:
            return _sqlite_execute(customer_db, sql)
        return _pyodbc_execute(customer_db, sql)
    except PermissionError:
        raise
    except Exception as exc:
        logger.exception("Query execution failed on '%s': %s", customer_db, exc)
        raise RuntimeError("Database query failed.") from exc


def get_available_databases() -> list[str]:
    """Return the list of valid customer database identifiers."""
    return sorted(VALID_DATABASES)
