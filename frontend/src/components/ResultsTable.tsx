interface ResultsTableProps {
  columns: string[];
  rows: Record<string, unknown>[];
}

export function ResultsTable({ columns, rows }: ResultsTableProps) {
  if (columns.length === 0 || rows.length === 0) return null;

  return (
    <div className="mt-3 overflow-x-auto rounded-lg border border-gray-200">
      <table className="min-w-full text-sm">
        <thead>
          <tr className="bg-gray-50">
            {columns.map((col) => (
              <th
                key={col}
                className="px-4 py-2 text-left font-medium text-gray-600 whitespace-nowrap border-b border-gray-200"
              >
                {col}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, i) => (
            <tr key={i} className={i % 2 === 0 ? 'bg-white' : 'bg-gray-50/50'}>
              {columns.map((col) => (
                <td
                  key={col}
                  className="px-4 py-2 text-gray-800 whitespace-nowrap border-b border-gray-100"
                >
                  {row[col] != null ? String(row[col]) : '—'}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
      {rows.length > 0 && (
        <div className="px-4 py-2 text-xs text-gray-400 bg-gray-50 border-t border-gray-200">
          {rows.length} row{rows.length !== 1 ? 's' : ''}
        </div>
      )}
    </div>
  );
}
