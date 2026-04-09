const MAX_ROWS = 100

interface ResultsTableProps {
  results: Record<string, unknown>[]
  rowCount: number
}

export default function ResultsTable({ results, rowCount }: ResultsTableProps) {
  if (results.length === 0) {
    return <p className="no-results">No results.</p>
  }

  const columns = Object.keys(results[0])
  const displayRows = results.slice(0, MAX_ROWS)
  const truncated = results.length > MAX_ROWS

  return (
    <div className="results-wrapper">
      <p className="results-count">
        {rowCount} row{rowCount !== 1 ? 's' : ''} returned
        {truncated && ` — showing first ${MAX_ROWS}`}
      </p>
      <div className="table-scroll">
        <table className="results-table">
          <thead>
            <tr>
              {columns.map((col) => (
                <th key={col}>{col}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {displayRows.map((row, i) => (
              <tr key={i}>
                {columns.map((col) => (
                  <td key={col}>{String(row[col] ?? '')}</td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
