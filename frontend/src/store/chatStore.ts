import { create } from "zustand";

export interface ChatMessage {
  id: string;
  role: "user" | "assistant" | "error";
  content: string;
  sql?: string | null;
  columns?: string[];
  rows?: unknown[][];
  rowCount?: number;
  executionTimeMs?: number;
  timestamp: Date;
}

interface ChatState {
  messages: ChatMessage[];
  isLoading: boolean;
  selectedDatabase: string;
  addMessage: (msg: Omit<ChatMessage, "id" | "timestamp">) => void;
  setLoading: (loading: boolean) => void;
  setDatabase: (db: string) => void;
  clearMessages: () => void;
}

export const useChatStore = create<ChatState>((set) => ({
  messages: [],
  isLoading: false,
  selectedDatabase: "",
  addMessage: (msg) =>
    set((state) => ({
      messages: [
        ...state.messages,
        { ...msg, id: crypto.randomUUID(), timestamp: new Date() },
      ],
    })),
  setLoading: (isLoading) => set({ isLoading }),
  setDatabase: (selectedDatabase) => set({ selectedDatabase }),
  clearMessages: () => set({ messages: [] }),
}));
