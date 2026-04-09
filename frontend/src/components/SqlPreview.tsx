interface SqlPreviewProps {
  sql: string | null
}

export default function SqlPreview({ sql }: SqlPreviewProps) {
  if (!sql) return null

  return (
    <div className="sql-preview">
      <p className="sql-preview-label">Generated SQL:</p>
      <pre className="sql-block">
        <code>{sql}</code>
      </pre>
    </div>
  )
}
