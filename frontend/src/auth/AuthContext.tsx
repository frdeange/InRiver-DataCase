import { createContext, useState, useCallback, useEffect, type ReactNode } from 'react';
import type { UserInfo, DatabaseInfo } from '../types';
import { login as apiLogin, getDatabases, clearTokens, getAccessToken } from '../api/client';
import { useChatStore } from '../store/chatStore';

interface AuthContextType {
  user: UserInfo | null;
  databases: DatabaseInfo[];
  selectedDatabase: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  selectDatabase: (dbName: string) => void;
}

export const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<UserInfo | null>(null);
  const [databases, setDatabases] = useState<DatabaseInfo[]>([]);
  const [selectedDatabase, setSelectedDatabase] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const isAuthenticated = !!user;

  // Check if there's already a token on mount (e.g. after refresh attempt)
  useEffect(() => {
    if (getAccessToken()) {
      loadDatabases();
    }
  }, []);

  const loadDatabases = useCallback(async () => {
    try {
      const dbs = await getDatabases();
      setDatabases(dbs);
    } catch {
      // Databases endpoint may not be available
    }
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    setIsLoading(true);
    try {
      // Clear previous session data before new login
      useChatStore.getState().clearMessages();

      await apiLogin(email, password);

      // Fetch databases after login
      let dbs: DatabaseInfo[] = [];
      try {
        dbs = await getDatabases();
      } catch {
        // Non-critical
      }
      setDatabases(dbs);
      setSelectedDatabase(dbs.find((d) => d.is_default)?.name || dbs[0]?.name || null);

      // Extract user info from email
      const domain = email.split('@')[1] || '';
      setUser({
        id: 0,
        email,
        full_name: email.split('@')[0],
        domain,
        databases: dbs.map((d) => d.name),
      });
    } finally {
      setIsLoading(false);
    }
  }, []);

  const selectDatabase = useCallback((dbName: string) => {
    setSelectedDatabase(dbName);
  }, []);

  const logout = useCallback(() => {
    clearTokens();
    setUser(null);
    setDatabases([]);
    setSelectedDatabase(null);
    useChatStore.getState().clearMessages();
  }, []);

  return (
    <AuthContext.Provider
      value={{ user, databases, selectedDatabase, isAuthenticated, isLoading, login, logout, selectDatabase }}
    >
      {children}
    </AuthContext.Provider>
  );
}
