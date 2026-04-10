import { apiRequest } from "./client";

export interface QueryResponse {
  answer: string;
  sql: string | null;
  columns: string[];
  rows: unknown[][];
  row_count: number;
  execution_time_ms: number;
  request_id: string;
}

export async function sendQuery(
  question: string,
  database: string,
  token: string
): Promise<QueryResponse> {
  return apiRequest<QueryResponse>("/api/query", {
    method: "POST",
    body: JSON.stringify({ question, database }),
    token,
  });
}

export async function getDatabases(
  token: string
): Promise<{ databases: string[] }> {
  return apiRequest<{ databases: string[] }>("/api/databases", { token });
}
