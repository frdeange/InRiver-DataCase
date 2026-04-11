import { describe, it, expect, beforeEach, vi } from 'vitest';
import { act } from '@testing-library/react';
import { useChatStore } from '../store/chatStore';

// Mock the API client
vi.mock('../api/client', () => ({
  submitQuery: vi.fn(),
}));

import { submitQuery } from '../api/client';
const mockSubmitQuery = vi.mocked(submitQuery);

beforeEach(() => {
  // Reset store state
  useChatStore.setState({ messages: [], isProcessing: false });
  mockSubmitQuery.mockReset();
});

describe('chatStore', () => {
  it('starts with empty messages', () => {
    const state = useChatStore.getState();
    expect(state.messages).toHaveLength(0);
    expect(state.isProcessing).toBe(false);
  });

  it('addMessage appends a message', () => {
    const { addMessage } = useChatStore.getState();
    addMessage({
      id: 'msg-1',
      role: 'user',
      content: 'Hello',
      timestamp: new Date(),
    });

    expect(useChatStore.getState().messages).toHaveLength(1);
    expect(useChatStore.getState().messages[0].content).toBe('Hello');
  });

  it('updateMessage modifies existing message', () => {
    const { addMessage, updateMessage } = useChatStore.getState();
    addMessage({
      id: 'msg-1',
      role: 'assistant',
      content: '',
      isLoading: true,
      timestamp: new Date(),
    });

    updateMessage('msg-1', { content: 'Done!', isLoading: false });

    const msg = useChatStore.getState().messages[0];
    expect(msg.content).toBe('Done!');
    expect(msg.isLoading).toBe(false);
  });

  it('clearMessages empties the list', () => {
    const { addMessage, clearMessages } = useChatStore.getState();
    addMessage({ id: '1', role: 'user', content: 'Hi', timestamp: new Date() });
    addMessage({ id: '2', role: 'assistant', content: 'Hello', timestamp: new Date() });

    clearMessages();
    expect(useChatStore.getState().messages).toHaveLength(0);
  });

  it('sendQuery adds user + assistant messages on success', async () => {
    mockSubmitQuery.mockResolvedValueOnce({
      answer: '10 products found.',
      sql: 'SELECT COUNT(*) FROM Products',
      database: 'db-acme',
      execution_time_ms: 55,
    });

    await act(async () => {
      await useChatStore.getState().sendQuery('How many products?');
    });

    const messages = useChatStore.getState().messages;
    expect(messages).toHaveLength(2);
    expect(messages[0].role).toBe('user');
    expect(messages[0].content).toBe('How many products?');
    expect(messages[1].role).toBe('assistant');
    expect(messages[1].content).toBe('10 products found.');
    expect(messages[1].sql).toBe('SELECT COUNT(*) FROM Products');
    expect(messages[1].isLoading).toBe(false);
  });

  it('sendQuery handles errors gracefully', async () => {
    mockSubmitQuery.mockRejectedValueOnce(new Error('Network error'));

    await act(async () => {
      await useChatStore.getState().sendQuery('Bad query');
    });

    const messages = useChatStore.getState().messages;
    expect(messages).toHaveLength(2);
    expect(messages[1].error).toBe('Network error');
    expect(messages[1].isLoading).toBe(false);
    expect(useChatStore.getState().isProcessing).toBe(false);
  });
});
