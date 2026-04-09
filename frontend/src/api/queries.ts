import client from "./client";

export interface QueryRequest {
  question: string;
  customer_db: string;
}

export interface QueryResult {
  question: string;
  customer_db: string;
  sql: string;
  results: Record<string, unknown>[];
  row_count: number;
  guardrail_passed: boolean;
  risk_level: string;
  blocked: boolean;
  block_reason: string | null;
  duration_ms: number;
}

interface BackendQueryResponse {
  question: string;
  customer_db: string;
  generated_sql: string;
  results: Record<string, unknown>[];
  row_count: number;
  guardrail_passed: boolean;
  risk_level: string;
  blocked: boolean;
  block_reason: string | null;
  duration_ms: number;
}

export interface DatabasesResponse {
  databases: string[];
}

export async function postQuery(req: QueryRequest): Promise<QueryResult> {
  const response = await client.post<BackendQueryResponse>("/api/query", req);
  const data = response.data;
  return {
    question: data.question,
    customer_db: data.customer_db,
    sql: data.generated_sql,
    results: data.results,
    row_count: data.row_count,
    guardrail_passed: data.guardrail_passed,
    risk_level: data.risk_level,
    blocked: data.blocked,
    block_reason: data.block_reason,
    duration_ms: data.duration_ms,
  };
}

export async function getDatabases(): Promise<DatabasesResponse> {
  const response = await client.get<DatabasesResponse>("/api/databases");
  return response.data;
}

export async function getSchema(customerDb: string): Promise<{ tables: unknown[] }> {
  const response = await client.get<{ tables: unknown[] }>(`/api/schema/${customerDb}`);
  return response.data;
}
