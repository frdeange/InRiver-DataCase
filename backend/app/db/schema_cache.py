from pathlib import Path


class SchemaCache:
    def __init__(self) -> None:
        self._cache: dict[str, str] = {}
        self._schema_path = Path(__file__).resolve().parent.parent.parent.parent / "database" / "schema.sql"

    def get_schema(self, database_name: str) -> str:
        if database_name not in self._cache:
            if self._schema_path.exists():
                self._cache[database_name] = self._schema_path.read_text(encoding="utf-8")
            else:
                self._cache[database_name] = "-- Schema not available"
        return self._cache[database_name]
