# Orchestrator — InRiver DataCase AI Pipeline

FastAPI service that runs the AI agent pipeline using Microsoft Agent Framework's `HandoffBuilder` pattern.

## Stack

Python 3.13 · FastAPI · Microsoft Agent Framework · FoundryAgent · sqlglot · structlog

## Run

```bash
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --port 8001
```

## Test

```bash
pytest                          # full suite (8 tests)
pytest tests/test_tools.py      # tools only
pytest tests/test_pipeline.py   # pipeline only
```

## API

| Method | Path | Description |
|--------|------|-------------|
| POST | `/process` | `{question, database, schema, user_email}` → `{answer, sql, database, execution_time_ms}` |
| GET | `/health` | `{"status": "healthy"}` |

## Pipeline Architecture

```
HandoffBuilder Workflow:

  SafetyAgent ──handoff──▶ SQLGeneratorAgent ──handoff──▶ FormatterAgent
                                  │
                           FunctionTools:
                           ├─ get_schema()      → PIM table definitions
                           ├─ validate_sql()    → sqlglot AST check
                           └─ execute_sql()     → run against tenant DB
```

### Agents (PromptAgents in Azure AI Foundry)

| Agent | Name | Role |
|-------|------|------|
| Safety | `inriver-safety` | Screens input for injection/harmful content |
| SQL Generator | `inriver-sql-generator` | Translates NL → T-SQL SELECT |
| Formatter | `inriver-response-formatter` | Converts SQL results → natural language |

### Two Pipeline Modes

- **`MockPipeline`** (`USE_MOCK_DB=true`): Works locally without Azure AI Foundry. Uses pattern matching for SQL generation and template responses.
- **`RealPipeline`** (`USE_MOCK_DB=false`): Uses `FoundryAgent` + `HandoffBuilder.build()` → `Workflow.run()`. Requires Azure AI Foundry project with provisioned agents.

## Architecture

```
app/
  main.py              FastAPI app with /process endpoint
  config.py            Settings (AI_PROJECT_ENDPOINT, MODEL_DEPLOYMENT, etc.)
  pipeline.py          MockPipeline + RealPipeline + factory
  agents/
    safety.py          FoundryAgent wrapper for PromptSafety
    sql_generator.py   FoundryAgent wrapper for SQLGenerator (with 3 FunctionTools)
    formatter.py       FoundryAgent wrapper for ResponseFormatter
  tools/
    sql_validator.py   @tool: sqlglot AST validation (SELECT-only)
    sql_executor.py    @tool: SQL execution (mock + Azure SQL)
    schema_provider.py @tool: PIM schema context for SQL generation
```

## Provisioning Agents

```bash
python scripts/setup-agents.py   # idempotent — skips existing agents
```
