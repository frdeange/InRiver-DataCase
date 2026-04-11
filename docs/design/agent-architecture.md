# Agent Architecture Design

## Overview

InRiver DataCase uses 3 persistent PromptAgents registered in Azure AI Foundry, orchestrated via Microsoft Agent Framework's `HandoffBuilder` pattern. The orchestrator runs as a separate FastAPI service.

## Agents

### 1. PromptSafety (`inriver-safety`)
- **Role**: First line of defense — screens user input for security threats
- **Screens for**: SQL injection patterns, cross-tenant data requests, harmful content, prompt manipulation
- **Output**: JSON `{"safe": true/false, "reason": "explanation"}`
- **Rationale**: Separating safety from SQL generation ensures malicious input never reaches the generation stage

### 2. SQLGenerator (`inriver-sql-generator`)
- **Role**: Translates natural language to T-SQL SELECT queries
- **Input**: User question + PIM schema context (via `get_schema` FunctionTool)
- **Output**: Raw T-SQL SELECT query string
- **FunctionTools attached**:
  - `get_schema` — provides table definitions for context
  - `validate_sql` — validates generated SQL via sqlglot AST parsing
  - `sql_executor` — executes validated SQL against the tenant database
- **Rationale**: The agent has tools to self-correct — if validation fails, it can regenerate

### 3. ResponseFormatter (`inriver-response-formatter`)
- **Role**: Converts raw SQL results into natural-language answers
- **Input**: Original question + SQL results (columns, rows)
- **Output**: Conversational answer with data insights
- **Rationale**: Separating formatting ensures consistent, user-friendly responses

## Why NOT a SQL Validator Agent?

SQL validation is deterministic (AST parsing with sqlglot) — no LLM reasoning needed. It's implemented as a `FunctionTool` on the SQLGenerator agent, which is more efficient and predictable than an LLM-based validator.

## Orchestration Pattern

```
User Question → HandoffBuilder
  ├─ 1. SafetyAgent (screens input)
  │     ├─ UNSAFE → reject with reason
  │     └─ SAFE → handoff to SQLGenerator
  ├─ 2. SQLGeneratorAgent (generates + validates + executes SQL)
  │     ├─ get_schema() → receives PIM table definitions
  │     ├─ generates T-SQL SELECT
  │     ├─ validate_sql() → sqlglot AST check
  │     ├─ execute_sql() → runs against tenant DB
  │     └─ handoff to ResponseFormatter with results
  └─ 3. ResponseFormatterAgent (formats answer)
        └─ Returns natural-language answer
```

### Why HandoffBuilder (not Sequential)?

`HandoffBuilder` allows agents to decide when to hand off, enabling the safety agent to short-circuit the pipeline on unsafe input. `SequentialBuilder` would run all agents regardless.

## Mock Pipeline

For local development without Azure AI Foundry, a `MockPipeline` provides:
- Keyword-based safety screening
- Pattern-matching SQL generation for common queries
- Template-based response formatting

This allows the full stack to run locally via `docker-compose up`.
