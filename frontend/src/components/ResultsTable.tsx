const MAX_ROWS = 100;

interface ResultsTableProps {
  results: Record<string, unknown>[];
  rowCount: number;
}

export default function ResultsTable({ results, rowCount }: ResultsTableProps) {
  if (results.length === 0) {
    return (
      <p className="text-sm text-gray-500 italic mt-2">No results found.</p>
    );
  }

  const columns = Object.keys(results[0]);
  const displayRows = results.slice(0, MAX_ROWS);
  const truncated = results.length > MAX_ROWS;

  return (
    <div className="mt-2">
      <div className="overflow-auto max-h-96 rounded-lg border border-gray-200">
        <table className="min-w-full divide-y divide-gray-200 text-sm">
          <thead className="bg-gray-50 sticky top-0">
            <tr>
              {columns.map((col) => (
                <th
                  key={col}
                  className="px-4 py-2 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider whitespace-nowrap"
                >
                  {col}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-100">
            {displayRows.map((row, i) => (
              <tr key={i} className={i % 2 === 0 ? "bg-white" : "bg-gray-50"}>
                {columns.map((col) => (
                  <td key={col} className="px-4 py-2 text-gray-800 whitespace-nowrap max-w-xs truncate">
                    {String(row[col] ?? "")}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="text-xs text-gray-500 mt-1">
        {truncated
          ? `Showing ${MAX_ROWS} of ${rowCount} rows`
          : `${rowCount} row${rowCount !== 1 ? "s" : ""}`}
      </p>
    </div>
  );
}
