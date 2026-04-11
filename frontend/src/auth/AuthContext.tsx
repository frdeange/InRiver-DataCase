import { createContext, useState, useCallback, useEffect, type ReactNode } from 'react';
import type { UserInfo, DatabaseInfo } from '../types';
import { login as apiLogin, getDatabases, clearTokens, getAccessToken } from '../api/client';

interface AuthContextType {
  user: UserInfo | null;
  databases: DatabaseInfo[];
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

export const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<UserInfo | null>(null);
  const [databases, setDatabases] = useState<DatabaseInfo[]>([]);
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
      await apiLogin(email, password);

      // Fetch databases after login
      let dbs: DatabaseInfo[] = [];
      try {
        dbs = await getDatabases();
      } catch {
        // Non-critical
      }
      setDatabases(dbs);

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

  const logout = useCallback(() => {
    clearTokens();
    setUser(null);
    setDatabases([]);
  }, []);

  return (
    <AuthContext.Provider
      value={{ user, databases, isAuthenticated, isLoading, login, logout }}
    >
      {children}
    </AuthContext.Provider>
  );
}
