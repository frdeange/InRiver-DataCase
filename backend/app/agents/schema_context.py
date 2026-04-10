from app.db.schema_cache import get_schema_for_tenant


async def get_schema_context(question: str, tenant_db: str) -> dict:
    """Get relevant schema context for the SQL generator."""
    schema = get_schema_for_tenant(tenant_db)
    if schema is None:
        return {
            "relevant_tables": [],
            "allowed_tables": set(),
            "allowed_columns": {},
            "schema_text": "",
        }

    # For PoC: return all tables in this tenant's schema
    # Production: use embeddings or keyword matching to filter relevant tables
    tables = schema["tables"]
    allowed_tables = set(t["name"].lower() for t in tables)
    allowed_columns = {}
    for t in tables:
        allowed_columns[t["name"].lower()] = set(
            c["name"].lower() for c in t["columns"]
        )

    schema_text = _format_schema_for_prompt(schema)

    return {
        "relevant_tables": [t["name"] for t in tables],
        "allowed_tables": allowed_tables,
        "allowed_columns": allowed_columns,
        "schema_text": schema_text,
        "tenant_db": tenant_db,
    }


def _format_schema_for_prompt(schema: dict) -> str:
    """Format schema metadata into a text block for the SQL Generator agent's prompt."""
    lines = []
    for table in schema["tables"]:
        cols = ", ".join(f'{c["name"]} ({c["type"]})' for c in table["columns"])
        lines.append(f"Table: {table['name']} — Columns: [{cols}]")
    if schema.get("foreign_keys"):
        lines.append("\nRelationships:")
        for fk in schema["foreign_keys"]:
            lines.append(
                f"  {fk['from_table']}.{fk['from_column']} → {fk['to_table']}.{fk['to_column']}"
            )
    return "\n".join(lines)
