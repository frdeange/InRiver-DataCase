interface Props {
  columns: string[];
  rows: unknown[][];
  rowCount: number;
}

export default function ResultsTable({ columns, rows, rowCount }: Props) {
  return (
    <div className="overflow-x-auto rounded-lg border border-gray-200">
      <table className="w-full text-left text-xs">
        <thead className="bg-gray-50 text-gray-600">
          <tr>
            {columns.map((col) => (
              <th key={col} className="whitespace-nowrap px-3 py-2 font-medium">
                {col}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100">
          {rows.map((row, i) => (
            <tr
              key={i}
              className="transition hover:bg-blue-50 even:bg-gray-50"
            >
              {row.map((cell, j) => (
                <td
                  key={j}
                  className="whitespace-nowrap px-3 py-1.5 text-gray-700"
                >
                  {cell == null ? (
                    <span className="italic text-gray-400">NULL</span>
                  ) : (
                    String(cell)
                  )}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
      <div className="border-t border-gray-200 bg-gray-50 px-3 py-1.5 text-right text-xs text-gray-500">
        {rowCount} {rowCount === 1 ? "row" : "rows"}
      </div>
    </div>
  );
}
