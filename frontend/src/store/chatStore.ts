import { create } from 'zustand';
import type { ChatMessage } from '../types';
import { submitQuery } from '../api/client';

interface ChatStore {
  messages: ChatMessage[];
  isProcessing: boolean;
  addMessage: (message: ChatMessage) => void;
  updateMessage: (id: string, updates: Partial<ChatMessage>) => void;
  clearMessages: () => void;
  sendQuery: (question: string, database?: string) => Promise<void>;
}

function generateId(): string {
  return `${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
}

export const useChatStore = create<ChatStore>((set, get) => ({
  messages: [],
  isProcessing: false,

  addMessage: (message) =>
    set((state) => ({ messages: [...state.messages, message] })),

  updateMessage: (id, updates) =>
    set((state) => ({
      messages: state.messages.map((m) => (m.id === id ? { ...m, ...updates } : m)),
    })),

  clearMessages: () => set({ messages: [] }),

  sendQuery: async (question, database) => {
    const userMessage: ChatMessage = {
      id: generateId(),
      role: 'user',
      content: question,
      timestamp: new Date(),
    };

    const assistantId = generateId();
    const loadingMessage: ChatMessage = {
      id: assistantId,
      role: 'assistant',
      content: '',
      timestamp: new Date(),
      isLoading: true,
    };

    set((state) => ({
      messages: [...state.messages, userMessage, loadingMessage],
      isProcessing: true,
    }));

    try {
      const response = await submitQuery(question, database);
      get().updateMessage(assistantId, {
        content: response.answer,
        sql: response.sql,
        database: response.database,
        execution_time_ms: response.execution_time_ms,
        columns: response.columns,
        rows: response.rows,
        isLoading: false,
      });
    } catch (err) {
      get().updateMessage(assistantId, {
        content: 'An error occurred while processing your query.',
        error: err instanceof Error ? err.message : 'Unknown error',
        isLoading: false,
      });
    } finally {
      set({ isProcessing: false });
    }
  },
}));
