import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  setAccessToken,
  setRefreshToken,
  getAccessToken,
  clearTokens,
  login,
  getDatabases,
  submitQuery,
} from '../api/client';

// Mock global fetch
const mockFetch = vi.fn();
global.fetch = mockFetch;

beforeEach(() => {
  clearTokens();
  mockFetch.mockReset();
});

describe('API Client', () => {
  describe('token management', () => {
    it('stores and retrieves access token in memory', () => {
      expect(getAccessToken()).toBeNull();
      setAccessToken('test-token');
      expect(getAccessToken()).toBe('test-token');
    });

    it('clears tokens', () => {
      setAccessToken('access');
      setRefreshToken('refresh');
      clearTokens();
      expect(getAccessToken()).toBeNull();
    });
  });

  describe('login', () => {
    it('sends credentials and stores tokens', async () => {
      const tokenResponse = {
        access_token: 'acc-123',
        refresh_token: 'ref-456',
        token_type: 'bearer',
      };
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve(tokenResponse),
      });

      const result = await login('alice@acme.com', 'AcmeUser1!');

      expect(mockFetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/v1/auth/login'),
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify({ email: 'alice@acme.com', password: 'AcmeUser1!' }),
        }),
      );
      expect(result.access_token).toBe('acc-123');
      expect(getAccessToken()).toBe('acc-123');
    });

    it('throws on invalid credentials', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 401,
        text: () => Promise.resolve('{"detail":"Invalid credentials"}'),
      });

      await expect(login('alice@acme.com', 'wrong')).rejects.toThrow('Invalid credentials');
    });
  });

  describe('authenticated requests', () => {
    it('attaches Bearer header', async () => {
      setAccessToken('my-token');
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve([{ name: 'db-acme', is_default: true }]),
      });

      await getDatabases();

      expect(mockFetch).toHaveBeenCalledWith(
        expect.stringContaining('/api/v1/databases'),
        expect.objectContaining({
          headers: expect.objectContaining({
            Authorization: 'Bearer my-token',
          }),
        }),
      );
    });

    it('submitQuery sends question to API', async () => {
      setAccessToken('my-token');
      const mockResponse = {
        answer: 'There are 10 products.',
        sql: 'SELECT COUNT(*) FROM Products',
        database: 'db-acme',
        execution_time_ms: 42,
      };
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve(mockResponse),
      });

      const result = await submitQuery('How many products?');

      expect(result.answer).toBe('There are 10 products.');
      expect(result.sql).toBe('SELECT COUNT(*) FROM Products');
    });
  });
});
