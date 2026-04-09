interface DatabaseSelectorProps {
  databases: string[]
  selected: string | null
  onSelect: (db: string) => void
  disabled?: boolean
}

export default function DatabaseSelector({
  databases,
  selected,
  onSelect,
  disabled = false,
}: DatabaseSelectorProps) {
  return (
    <div className="field-group">
      <label htmlFor="db-select" className="field-label">
        Database
      </label>
      <select
        id="db-select"
        className="select"
        value={selected ?? ''}
        onChange={(e) => onSelect(e.target.value)}
        disabled={disabled}
      >
        <option value="" disabled>
          Select a database...
        </option>
        {databases.map((db) => (
          <option key={db} value={db}>
            {db.toUpperCase()}
          </option>
        ))}
      </select>
    </div>
  )
}
