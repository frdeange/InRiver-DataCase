import type { TokenResponse, DatabaseInfo, QueryResponse } from '../types';

const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

let accessToken: string | null = null;
let refreshToken: string | null = null;

export function setAccessToken(token: string | null) {
  accessToken = token;
}

export function setRefreshToken(token: string | null) {
  refreshToken = token;
}

export function getAccessToken(): string | null {
  return accessToken;
}

class ApiError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
  }
}

async function request<T>(
  method: string,
  path: string,
  body?: unknown,
  skipAuth = false,
): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  if (!skipAuth && accessToken) {
    headers['Authorization'] = `Bearer ${accessToken}`;
  }

  let response = await fetch(`${BASE_URL}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  // Attempt token refresh on 401
  if (response.status === 401 && !skipAuth && refreshToken) {
    const refreshed = await refreshAccessToken();
    if (refreshed) {
      headers['Authorization'] = `Bearer ${accessToken}`;
      response = await fetch(`${BASE_URL}${path}`, {
        method,
        headers,
        body: body ? JSON.stringify(body) : undefined,
      });
    }
  }

  if (!response.ok) {
    const errorBody = await response.text();
    let message: string;
    try {
      const parsed = JSON.parse(errorBody);
      message = parsed.detail || parsed.message || errorBody;
    } catch {
      message = errorBody;
    }
    throw new ApiError(response.status, message);
  }

  return response.json();
}

async function refreshAccessToken(): Promise<boolean> {
  try {
    const response = await fetch(`${BASE_URL}/api/v1/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refresh_token: refreshToken }),
    });

    if (!response.ok) return false;

    const data = await response.json();
    accessToken = data.access_token;
    return true;
  } catch {
    return false;
  }
}

export async function login(email: string, password: string): Promise<TokenResponse> {
  const data = await request<TokenResponse>(
    'POST',
    '/api/v1/auth/login',
    { email, password },
    true,
  );
  setAccessToken(data.access_token);
  setRefreshToken(data.refresh_token);
  return data;
}

export async function getDatabases(): Promise<DatabaseInfo[]> {
  return request<DatabaseInfo[]>('GET', '/api/v1/databases');
}

export async function submitQuery(question: string, database?: string): Promise<QueryResponse> {
  return request<QueryResponse>('POST', '/api/v1/query', { question, database });
}

export async function healthCheck(): Promise<{ status: string }> {
  return request<{ status: string }>('GET', '/health', undefined, true);
}

export function clearTokens() {
  accessToken = null;
  refreshToken = null;
}
