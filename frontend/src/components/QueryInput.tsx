import { useState, useRef, type KeyboardEvent } from "react";
import { useAuth } from "../auth/useAuth";
import { useChatStore } from "../store/chatStore";
import { sendQuery } from "../api/queries";

export default function QueryInput() {
  const [input, setInput] = useState("");
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const { acquireToken } = useAuth();
  const { selectedDatabase, isLoading, addMessage, setLoading } =
    useChatStore();

  const canSubmit = input.trim() && selectedDatabase && !isLoading;

  async function handleSubmit() {
    const question = input.trim();
    if (!question || !selectedDatabase) return;

    setInput("");
    if (textareaRef.current) textareaRef.current.style.height = "auto";

    addMessage({ role: "user", content: question });
    setLoading(true);

    try {
      const token = await acquireToken();
      const res = await sendQuery(question, selectedDatabase, token);

      addMessage({
        role: "assistant",
        content: res.answer,
        sql: res.sql,
        columns: res.columns,
        rows: res.rows,
        rowCount: res.row_count,
        executionTimeMs: res.execution_time_ms,
      });
    } catch (err) {
      addMessage({
        role: "error",
        content: err instanceof Error ? err.message : "An error occurred",
      });
    } finally {
      setLoading(false);
    }
  }

  function handleKeyDown(e: KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      if (canSubmit) handleSubmit();
    }
  }

  function handleInput() {
    const el = textareaRef.current;
    if (!el) return;
    el.style.height = "auto";
    el.style.height = `${Math.min(el.scrollHeight, 96)}px`;
  }

  return (
    <div className="border-t border-gray-200 bg-white px-4 py-3">
      <div className="mx-auto flex max-w-3xl items-end gap-3">
        <textarea
          ref={textareaRef}
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={handleKeyDown}
          onInput={handleInput}
          placeholder={
            selectedDatabase
              ? "Ask a question about your data..."
              : "Select a database first"
          }
          disabled={!selectedDatabase || isLoading}
          rows={1}
          className="flex-1 resize-none rounded-xl border border-gray-300 px-4 py-2.5 text-sm outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-200 disabled:bg-gray-100"
        />
        <button
          onClick={handleSubmit}
          disabled={!canSubmit}
          className="rounded-xl bg-blue-700 px-5 py-2.5 text-sm font-semibold text-white shadow transition hover:bg-blue-800 disabled:cursor-not-allowed disabled:opacity-40"
        >
          Send
        </button>
      </div>
    </div>
  );
}
