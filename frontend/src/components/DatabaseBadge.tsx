import type { DatabaseInfo } from '../types';

interface DatabaseBadgeProps {
  databases: DatabaseInfo[];
}

export function DatabaseBadge({ databases }: DatabaseBadgeProps) {
  if (databases.length === 0) return null;

  const defaultDb = databases.find((d) => d.is_default);
  const displayName = defaultDb?.name || databases[0].name;

  return (
    <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-emerald-50 border border-emerald-200">
      <span className="relative flex h-2.5 w-2.5">
        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
        <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500" />
      </span>
      <span className="text-sm font-medium text-emerald-800">{displayName}</span>
      {databases.length > 1 && (
        <span className="text-xs text-emerald-600 bg-emerald-100 px-1.5 py-0.5 rounded-full">
          +{databases.length - 1}
        </span>
      )}
    </div>
  );
}
