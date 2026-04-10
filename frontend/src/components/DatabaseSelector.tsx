import { useState, useEffect } from "react";
import { useAuth } from "../auth/useAuth";
import { useChatStore } from "../store/chatStore";
import { getDatabases } from "../api/queries";

export default function DatabaseSelector() {
  const [databases, setDatabases] = useState<string[]>([]);
  const [error, setError] = useState("");
  const selectedDatabase = useChatStore((s) => s.selectedDatabase);
  const setDatabase = useChatStore((s) => s.setDatabase);
  const { acquireToken } = useAuth();

  useEffect(() => {
    let cancelled = false;

    async function fetchDatabases() {
      try {
        const token = await acquireToken();
        const res = await getDatabases(token);
        if (!cancelled) setDatabases(res.databases);
      } catch (err) {
        if (!cancelled)
          setError(
            err instanceof Error ? err.message : "Failed to load databases"
          );
      }
    }

    fetchDatabases();
    return () => {
      cancelled = true;
    };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  if (error) {
    return (
      <span className="text-xs text-red-200" title={error}>
        DB error
      </span>
    );
  }

  return (
    <select
      value={selectedDatabase}
      onChange={(e) => setDatabase(e.target.value)}
      className="rounded border border-blue-400 bg-blue-600 px-2 py-1 text-sm text-white outline-none transition hover:bg-blue-500 focus:ring-2 focus:ring-blue-300"
    >
      <option value="">Select a database</option>
      {databases.map((db) => (
        <option key={db} value={db}>
          {db}
        </option>
      ))}
    </select>
  );
}
