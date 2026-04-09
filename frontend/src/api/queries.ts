import client from "./client";

export interface QueryRequest {
  question: string;
  customer_db: string;
}

export interface QueryResult {
  sql: string;
  explanation: string;
  results: Record<string, unknown>[];
  row_count: number;
}

export interface DatabasesResponse {
  databases: string[];
}

export async function postQuery(req: QueryRequest): Promise<QueryResult> {
  const response = await client.post<QueryResult>("/api/query", req);
  return response.data;
}

export async function getDatabases(): Promise<DatabasesResponse> {
  const response = await client.get<DatabasesResponse>("/api/databases");
  return response.data;
}

export async function getSchema(customerDb: string): Promise<{ tables: unknown[] }> {
  const response = await client.get<{ tables: unknown[] }>(`/api/schema/${customerDb}`);
  return response.data;
}
