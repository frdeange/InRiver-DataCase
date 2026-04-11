import sqlglot
from sqlglot import exp


FORBIDDEN_TYPES = (
    exp.Insert,
    exp.Update,
    exp.Delete,
    exp.Drop,
    exp.Alter,
    exp.Create,
    exp.Command,
)


class SQLValidator:
    def validate(self, sql: str) -> tuple[bool, str]:
        try:
            statements = sqlglot.parse(sql, error_level=sqlglot.ErrorLevel.RAISE)
        except sqlglot.errors.ParseError as e:
            return False, f"SQL parse error: {e}"

        if not statements:
            return False, "Empty SQL statement"

        if len(statements) > 1:
            return False, "Multiple statements are not allowed"

        statement = statements[0]
        if statement is None:
            return False, "Empty SQL statement"

        # Check for forbidden statement types
        for forbidden in FORBIDDEN_TYPES:
            if isinstance(statement, forbidden):
                type_name = type(statement).__name__
                return False, f"{type_name} statements are not allowed"

        # Check for EXEC/EXECUTE commands in the AST
        for node in statement.walk():
            if isinstance(node, exp.Command):
                cmd_text = node.this if isinstance(node.this, str) else ""
                if cmd_text.upper() in ("EXEC", "EXECUTE", "TRUNCATE"):
                    return False, f"{cmd_text.upper()} statements are not allowed"

        # Must be a SELECT
        if not isinstance(statement, exp.Select):
            type_name = type(statement).__name__
            return False, f"Only SELECT statements are allowed, got {type_name}"

        return True, "Query is valid"
