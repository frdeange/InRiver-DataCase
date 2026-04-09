import { useEffect, useState } from "react";
import { getDatabases } from "../api/queries";

const DB_DISPLAY_NAMES: Record<string, string> = {
  acme: "ACME Corp",
  nova: "Nova Retail",
  apex: "Apex Distribution",
};

function getDisplayName(db: string): string {
  return DB_DISPLAY_NAMES[db] ?? db.charAt(0).toUpperCase() + db.slice(1);
}

interface DatabaseSelectorProps {
  value: string;
  onChange: (db: string) => void;
}

export default function DatabaseSelector({ value, onChange }: DatabaseSelectorProps) {
  const [databases, setDatabases] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getDatabases()
      .then((res) => {
        setDatabases(res.databases);
        if (res.databases.length > 0 && !value) {
          onChange(res.databases[0]);
        }
      })
      .catch(() => setError("Failed to load databases"))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="flex items-center gap-2 text-sm text-gray-500">
        <svg className="animate-spin h-4 w-4 text-indigo-500" fill="none" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
        </svg>
        Loading databases…
      </div>
    );
  }

  if (error) {
    return <span className="text-sm text-red-500">{error}</span>;
  }

  return (
    <div className="flex items-center gap-2">
      <label htmlFor="db-selector" className="text-sm font-medium text-gray-700 whitespace-nowrap">
        Database:
      </label>
      <select
        id="db-selector"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="text-sm border border-gray-300 rounded-lg px-3 py-1.5 bg-white text-gray-900 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
        aria-label="Select customer database"
      >
        {databases.map((db) => (
          <option key={db} value={db}>
            {getDisplayName(db)}
          </option>
        ))}
      </select>
    </div>
  );
}
