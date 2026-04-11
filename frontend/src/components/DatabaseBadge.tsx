import { useState } from 'react';
import type { DatabaseInfo } from '../types';

interface DatabaseBadgeProps {
  databases: DatabaseInfo[];
  selectedDb?: string;
  onSelect?: (dbName: string) => void;
}

export function DatabaseBadge({ databases, selectedDb, onSelect }: DatabaseBadgeProps) {
  const [isOpen, setIsOpen] = useState(false);

  if (databases.length === 0) return null;

  const activeName = selectedDb || databases.find((d) => d.is_default)?.name || databases[0].name;

  // Single database — read-only badge
  if (databases.length === 1) {
    return (
      <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-emerald-50 border border-emerald-200">
        <span className="relative flex h-2.5 w-2.5">
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
          <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500" />
        </span>
        <span className="text-sm font-medium text-emerald-800">{activeName}</span>
      </div>
    );
  }

  // Multiple databases — selector
  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-emerald-50 border border-emerald-200 hover:bg-emerald-100 transition-colors"
      >
        <span className="relative flex h-2.5 w-2.5">
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
          <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500" />
        </span>
        <span className="text-sm font-medium text-emerald-800">{activeName}</span>
        <span className="text-xs text-emerald-600 bg-emerald-100 px-1.5 py-0.5 rounded-full">
          {databases.length} DBs
        </span>
        <svg className="w-3.5 h-3.5 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {isOpen && (
        <div className="absolute top-full left-0 mt-1 bg-white border border-gray-200 rounded-lg shadow-lg z-10 min-w-[160px]">
          {databases.map((db) => (
            <button
              key={db.name}
              onClick={() => {
                onSelect?.(db.name);
                setIsOpen(false);
              }}
              className={`w-full text-left px-3 py-2 text-sm hover:bg-gray-50 first:rounded-t-lg last:rounded-b-lg ${
                db.name === activeName ? 'text-indigo-700 font-medium bg-indigo-50' : 'text-gray-700'
              }`}
            >
              {db.name}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
