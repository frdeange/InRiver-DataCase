export interface LoginRequest {
  email: string;
  password: string;
}

export interface TokenResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
}

export interface UserInfo {
  id: number;
  email: string;
  full_name: string;
  domain: string;
  databases: string[];
}

export interface DatabaseInfo {
  name: string;
  is_default: boolean;
}

export interface QueryRequest {
  question: string;
  database?: string;
}

export interface QueryResponse {
  answer: string;
  sql: string;
  database: string;
  execution_time_ms: number;
  columns?: string[];
  rows?: Record<string, unknown>[];
}

export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  sql?: string;
  database?: string;
  execution_time_ms?: number;
  columns?: string[];
  rows?: Record<string, unknown>[];
  timestamp: Date;
  isLoading?: boolean;
  error?: string;
}
