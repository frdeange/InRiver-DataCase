# Agent Architecture Review — Oracle Report

**Date:** 2025-07-15
**Author:** Oracle (AI/Agent Orchestration Engineer)
**Status:** Analysis — no implementation changes

---

## 1. Current State Assessment

### How agents are used today

The system uses `agent-framework==1.0.1` with three AI-powered agents and two deterministic components:

| Component | Type | Framework Usage |
|---|---|---|
| `PromptSafetyAgent` | AI agent | `Agent` + `FoundryChatClient` — transient in-process object |
| `SQLGeneratorAgent` | AI agent | `Agent` + `FoundryChatClient` — transient in-process object |
| `ResponseFormatterAgent` | AI agent | `Agent` + `FoundryChatClient` — transient in-process object |
| `sql_validator` | Deterministic | Pure Python (sqlglot AST parsing) — no framework |
| `schema_context` | Deterministic | Pure Python (schema cache lookup) — no framework |

**Architecture pattern:** Each agent is instantiated per-request as a transient `Agent(client=FoundryChatClient(...))` object. The orchestration is a custom sequential Python pipeline in `orchestrator.py`.

### Are they "hosted in Foundry"?

**No.** The current agents are **not hosted in Foundry**. They are:

- **Transient Python objects** — created, invoked, and garbage-collected within a single request
- **Using Foundry's API** — `FoundryChatClient` sends chat completions to an Azure AI Foundry model deployment
- **Not registered** — no persistent agent definition exists in the Foundry project; there are no `PromptAgent` or `HostedAgent` resources in Azure

The current setup is equivalent to calling the OpenAI chat completions API with system prompts — the "Agent" wrapper adds middleware/telemetry but the agent has no persistent identity in Foundry.

---

## 2. What "Hosted in Foundry" Means

Azure AI Foundry supports two hosted agent types:

### a) PromptAgent (Foundry-managed)
- Registered in the Foundry project with a **name, version, instructions, and tool definitions**
- Persisted as a resource — survives process restarts
- Accessed via `FoundryAgent(agent_name="...", agent_version="...")` instead of `Agent(client=..., instructions=...)`
- Foundry manages the model binding, system prompt, and tool schemas
- Supports **sessions** (conversation history managed server-side)
- Created via Azure AI Foundry portal, SDK, or REST API

### b) HostedAgent (container-hosted)
- Your code packaged as a container, registered in Foundry
- Foundry routes requests to your container
- Full control over execution logic
- More complex to deploy

### What it takes to migrate

For each of the three AI agents (Safety, SQLGen, Formatter):

1. **Register as a PromptAgent** in the Foundry project — define name, instructions, model, and any tool schemas
2. **Replace** `Agent(client=FoundryChatClient(...), instructions=...)` with `FoundryAgent(project_endpoint=..., agent_name=..., agent_version=...)`
3. **Move instructions** from Python constants into the Foundry agent definition (or override at call time)
4. **Infrastructure:** Add Bicep resources for agent registration (or use SDK/CLI in deployment scripts)

The `FoundryAgent` class in `agent-framework` already exists and connects to registered Foundry agents. The code change per agent is small; the infrastructure change is the main work.

---

## 3. Orchestration Gap Analysis

### Current orchestration

`orchestrator.py` implements a **custom sequential pipeline**:

```
Safety → Schema → SQLGen → Validate → (retry loop) → Execute → Format
```

This is plain Python with `if/else` and `for` loops. The Agent Framework is not used for orchestration — only for individual agent calls.

### Agent Framework orchestration primitives (v1.0.1)

The framework provides a **Workflow** engine (Pregel-like graph execution):

| Primitive | Description |
|---|---|
| `WorkflowBuilder.add_chain([a, b, c])` | Sequential execution: a → b → c |
| `WorkflowBuilder.add_edge(a, b, condition=fn)` | Conditional edge between executors |
| `WorkflowBuilder.add_switch_case_edge_group(source, cases)` | Switch/case routing |
| `WorkflowBuilder.add_fan_out_edges(source, targets)` | Parallel fan-out |
| `WorkflowBuilder.add_fan_in_edges(sources, target)` | Parallel fan-in (join) |
| `Executor` | Base class for custom processing nodes |
| `WorkflowAgent` | Wraps a Workflow as an Agent |

### Which pattern fits?

The pipeline is **mostly sequential with a conditional retry loop**. The recommended pattern:

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌───────────┐
│  Safety  │───▶│  Schema  │───▶│  SQLGen  │───▶│ Validator │
│  Agent   │    │ Executor │    │  Agent   │    │ Executor  │
└──────────┘    └──────────┘    └──────────┘    └───────────┘
     │                                                │
     │ UNSAFE → exit                      VALID ──────┼──────┐
     ▼                                    INVALID ────┘      │
   (abort)                                (retry→SQLGen,     ▼
                                           max 2x)    ┌───────────┐    ┌───────────┐
                                                      │  Execute  │───▶│ Formatter │
                                                      │ Executor  │    │   Agent   │
                                                      └───────────┘    └───────────┘
```

**Implementation approach:**

1. **Safety, SQLGen, Formatter** → `FoundryAgent` nodes (or `Agent` wrapping `FoundryChatClient`)
2. **Schema, Validator, Execute** → Custom `Executor` subclasses (deterministic, no AI)
3. **Retry loop** → `add_edge(validator, sql_gen, condition=lambda msg: not msg.is_valid)` + `add_edge(validator, executor, condition=lambda msg: msg.is_valid)` with a max-iteration guard
4. **Safety abort** → `add_switch_case_edge_group(safety, [Case(is_safe, schema), Default(abort_executor)])`
5. **Wrap as** `WorkflowAgent` for a clean single entry point

The `WorkflowBuilder` graph model maps well to this pipeline. The retry loop is the trickiest part — it requires a conditional back-edge from Validator to SQLGen with an iteration counter in the workflow `State`.

---

## 4. Separate Container App — Analysis

### When would the Agent Framework need its own Container App?

| Scenario | Separate Container App | In-process with FastAPI |
|---|---|---|
| Agent execution is CPU/memory intensive | ✅ Isolate resource usage | ❌ Competes with API |
| Need independent scaling | ✅ Scale agents separately | ❌ Coupled scaling |
| Multiple frontends consume agents | ✅ Shared agent service | ❌ Each frontend embeds agents |
| Simple PoC / single API | ❌ Over-engineered | ✅ Simpler deployment |
| Agent calls are I/O-bound (LLM API calls) | ❌ Adds latency | ✅ Async I/O is fine |

### Recommendation for InRiver-DataCase

**Not justified at this stage.** Reasons:

1. **Agent work is I/O-bound** — all three AI agents wait on Foundry API calls; CPU usage is minimal
2. **Single consumer** — only the FastAPI backend calls the agents
3. **Added latency** — a separate container adds network hop + serialization overhead
4. **Operational complexity** — two containers to deploy, monitor, and scale instead of one
5. **No resource contention** — `asyncio` handles concurrent LLM calls efficiently in-process

**When to revisit:** If agents gain tools that do heavy compute (e.g., data analysis, file processing), or if multiple services need to invoke the same agent pipeline, a separate Container App becomes justified.

---

## 5. sql_validator.py — Agent or Tool?

### Current implementation

`sql_validator.py` is a **deterministic security gate**: regex scans, AST parsing via `sqlglot`, table/column allowlist enforcement, JOIN limits, and `TOP` injection. It has zero AI involvement.

### Should it be an Agent Framework agent?

**No.** It should remain a deterministic `Executor`, not an `Agent`. Reasons:

1. **Security-critical** — validation must be deterministic and auditable; LLM-based validation could be bypassed by adversarial inputs
2. **Zero latency** — AST parsing is microseconds vs. hundreds of milliseconds for an LLM call
3. **Testable** — unit tests can exhaustively cover all SQL injection patterns
4. **No hallucination risk** — regex + AST parsing cannot "decide" an unsafe query is safe

### How it fits in the Workflow

Wrap it as a custom `Executor` subclass:

```python
class SQLValidatorExecutor(Executor):
    async def execute(self, message, ...):
        result = validate_sql(message.sql, message.tenant_db, ...)
        # Emit result message for conditional routing
```

This integrates cleanly with the Workflow graph — the validator is a node that emits valid/invalid signals for edge conditions, but its internal logic stays pure Python.

### Should it be a tool?

It could be registered as a `FunctionTool` on the SQLGenerator agent, letting the agent self-validate before responding. However, this is **not recommended** because:

- The agent could choose not to call the tool
- The agent could ignore the tool's output
- The security boundary must be **external to the agent**, not self-policed

---

## 6. Recommended Pipeline Redesign

### Target architecture

```python
from agent_framework import WorkflowBuilder, WorkflowAgent, Executor
from agent_framework.foundry import FoundryAgent

# 1. Define Foundry-hosted agents
safety_agent = FoundryAgent(
    project_endpoint=settings.endpoint,
    agent_name="prompt-safety",
    agent_version="1.0",
    credential=get_credential(),
)

sql_gen_agent = FoundryAgent(
    project_endpoint=settings.endpoint,
    agent_name="sql-generator",
    agent_version="1.0",
    credential=get_credential(),
)

formatter_agent = FoundryAgent(
    project_endpoint=settings.endpoint,
    agent_name="response-formatter",
    agent_version="1.0",
    credential=get_credential(),
)

# 2. Define deterministic executors
schema_executor = SchemaContextExecutor()      # wraps get_schema_context()
validator_executor = SQLValidatorExecutor()     # wraps validate_sql()
query_executor = QueryExecutionExecutor()       # wraps execute_validated_query()
abort_executor = AbortExecutor()                # returns error response

# 3. Build workflow graph
workflow = (
    WorkflowBuilder()
    .add_edge(safety_agent, schema_executor,
              condition=lambda msg: msg.is_safe)
    .add_edge(safety_agent, abort_executor,
              condition=lambda msg: not msg.is_safe)
    .add_edge(schema_executor, sql_gen_agent)
    .add_edge(sql_gen_agent, validator_executor)
    .add_edge(validator_executor, sql_gen_agent,
              condition=lambda msg: not msg.is_valid and msg.attempt < 3)
    .add_edge(validator_executor, query_executor,
              condition=lambda msg: msg.is_valid)
    .add_edge(validator_executor, abort_executor,
              condition=lambda msg: not msg.is_valid and msg.attempt >= 3)
    .add_edge(query_executor, formatter_agent)
    .build()
)

# 4. Expose as a single agent
pipeline_agent = WorkflowAgent(workflow=workflow, name="DataCasePipeline")
```

### Key design decisions

1. **FoundryAgent instead of Agent+FoundryChatClient** — agents become persistent Foundry resources with versioned definitions
2. **Deterministic nodes as Executor subclasses** — schema lookup, SQL validation, and query execution are not agents
3. **Security gate is external** — the validator is a workflow node that the SQL generator cannot bypass
4. **Retry loop via conditional back-edge** — Workflow's conditional edges handle the SQLGen→Validate→retry cycle with an attempt counter in State
5. **Audit logging** — use Agent Framework middleware (`AgentMiddleware`) for cross-cutting audit logging instead of manual `audit_logger.log_event()` calls

---

## 7. Migration Steps

### Phase 1: Register Foundry Agents (infra change)

1. Register `prompt-safety` PromptAgent in Foundry (name, instructions, model binding)
2. Register `sql-generator` PromptAgent in Foundry
3. Register `response-formatter` PromptAgent in Foundry
4. Add agent registration to deployment pipeline (Bicep or SDK script)

### Phase 2: Switch to FoundryAgent (code change)

1. Replace `Agent(client=FoundryChatClient(...), instructions=...)` with `FoundryAgent(agent_name=..., agent_version=...)`
2. Remove inline instruction constants (moved to Foundry agent definitions)
3. Validate behavior is identical

### Phase 3: Build Workflow graph (orchestration change)

1. Create custom `Executor` subclasses for Schema, Validator, QueryExec, and Abort
2. Define the Workflow graph with `WorkflowBuilder`
3. Implement message types for inter-node communication (safety result, schema context, SQL result, validation result)
4. Add retry counter to Workflow `State`
5. Wrap as `WorkflowAgent`
6. Add audit logging via `AgentMiddleware`

### Phase 4: Replace orchestrator.py

1. Replace `orchestrate_query()` with `pipeline_agent.run()`
2. Update `routes.py` to call the WorkflowAgent
3. Remove `orchestrator.py`
4. End-to-end testing

---

## 8. Security Considerations

| Concern | Recommendation |
|---|---|
| SQL validation must remain deterministic | ✅ `SQLValidatorExecutor` wraps existing `validate_sql()` — no AI |
| Validator cannot be bypassed | ✅ Workflow graph enforces: SQLGen output **must** pass through Validator before Execution |
| Retry loop must be bounded | ✅ Attempt counter in Workflow State, abort after max retries |
| Auth context must flow through pipeline | ✅ Pass via Workflow State or context providers |
| Audit trail must be complete | ✅ AgentMiddleware provides cross-cutting logging for all nodes |
| Agent instructions shouldn't be tamperable | ✅ FoundryAgent instructions are server-side, not in client code |
| Cross-tenant isolation | ⚠️ Ensure tenant_db and auth_context are propagated through Workflow State and validated at each step |

---

## 9. Summary

| Dimension | Current | Target |
|---|---|---|
| Agent hosting | Transient in-process `Agent` objects | `FoundryAgent` connected to registered PromptAgents |
| Orchestration | Custom Python pipeline | `WorkflowBuilder` graph with conditional edges |
| Validation | Pure Python (correct) | Same — wrapped as `Executor` (no change to logic) |
| Container topology | Single FastAPI container | Same — no separate agent container needed |
| Retry logic | Python `for` loop | Conditional back-edge with State counter |
| Audit logging | Manual per-step calls | `AgentMiddleware` (cross-cutting) |
| Instructions | Hardcoded Python constants | Foundry agent definitions (versioned, server-side) |
