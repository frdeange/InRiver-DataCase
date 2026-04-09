export interface QueryRequest {
  question: string
  customer_db: string
  user: string
}

export interface QueryResponse {
  question: string
  customer_db: string
  generated_sql: string | null
  results: Record<string, unknown>[]
  row_count: number
  guardrail_passed: boolean
  risk_level: string
  blocked: boolean
  block_reason: string | null
  duration_ms: number
}

export interface DatabasesResponse {
  databases: string[]
}

const BASE_URL: string = (import.meta.env.VITE_API_URL as string | undefined) ?? ''

function authHeaders(token?: string | null): Record<string, string> {
  if (token) {
    return { Authorization: `Bearer ${token}` }
  }
  return {}
}

export async function fetchDatabases(
  user: string,
  token?: string | null,
): Promise<DatabasesResponse> {
  const url = `${BASE_URL}/api/databases?user=${encodeURIComponent(user)}`
  const res = await fetch(url, {
    headers: {
      ...authHeaders(token),
    },
  })
  if (!res.ok) {
    throw new Error(`Failed to fetch databases: ${res.status} ${res.statusText}`)
  }
  return res.json() as Promise<DatabasesResponse>
}

export async function submitQuery(
  req: QueryRequest,
  token?: string | null,
): Promise<QueryResponse> {
  const url = `${BASE_URL}/api/query`
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...authHeaders(token),
    },
    body: JSON.stringify(req),
  })
  if (!res.ok) {
    throw new Error(`Query failed: ${res.status} ${res.statusText}`)
  }
  return res.json() as Promise<QueryResponse>
}
