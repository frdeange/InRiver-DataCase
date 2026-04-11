"""Schema provider tool — supplies PIM schema context to the SQL generator."""

from __future__ import annotations

from pathlib import Path

_SCHEMA_PATHS = [
    Path("/workspaces/InRiver-DataCase/database/schema.sql"),
    Path(__file__).resolve().parent.parent.parent.parent / "database" / "schema.sql",
]


def get_schema(database: str) -> str:
    """Return the PIM CREATE TABLE statements for *database*.

    The schema is identical across tenant databases.
    """
    for path in _SCHEMA_PATHS:
        if path.is_file():
            return path.read_text(encoding="utf-8")

    return _fallback_schema()


def _fallback_schema() -> str:
    """Minimal inline schema when the file is unavailable."""
    return (
        "-- InRiver PIM Schema (summary)\n"
        "-- Tables: Categories, Products, Attributes, "
        "ProductAttributes, Customers, Orders\n"
    )
