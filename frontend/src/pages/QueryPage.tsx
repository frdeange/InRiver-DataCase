import { useEffect, useState } from 'react'
import { useAuth } from '../auth/useAuth'
import { fetchDatabases, submitQuery } from '../api/queryApi'
import type { QueryResponse } from '../api/queryApi'
import DatabaseSelector from '../components/DatabaseSelector'
import QueryInput from '../components/QueryInput'
import SqlPreview from '../components/SqlPreview'
import ResultsTable from '../components/ResultsTable'
import AuditBadge from '../components/AuditBadge'

export default function QueryPage() {
  const { user, logout, getAccessToken } = useAuth()

  const [databases, setDatabases] = useState<string[]>([])
  const [selectedDb, setSelectedDb] = useState<string | null>(null)
  const [isLoadingDbs, setIsLoadingDbs] = useState(false)
  const [isQuerying, setIsQuerying] = useState(false)
  const [response, setResponse] = useState<QueryResponse | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!user) return
    setIsLoadingDbs(true)
    getAccessToken()
      .then((token) => fetchDatabases(user, token))
      .then((data) => {
        setDatabases(data.databases)
        if (data.databases.length > 0) {
          setSelectedDb(data.databases[0])
        }
      })
      .catch((err: unknown) => {
        setError(err instanceof Error ? err.message : 'Failed to load databases')
      })
      .finally(() => setIsLoadingDbs(false))
  }, [user, getAccessToken])

  const handleQuery = async (question: string) => {
    if (!user || !selectedDb) return
    setIsQuerying(true)
    setError(null)
    setResponse(null)
    try {
      const token = await getAccessToken()
      const result = await submitQuery({ question, customer_db: selectedDb, user }, token)
      setResponse(result)
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Query failed')
    } finally {
      setIsQuerying(false)
    }
  }

  return (
    <div className="page">
      <header className="header">
        <h1 className="header-title">InRiver Agentic SQL Demo</h1>
        <div className="header-user">
          <span className="user-email">{user}</span>
          <button className="btn btn-secondary btn-sm" onClick={logout}>
            Sign Out
          </button>
        </div>
      </header>

      <main className="main">
        {isLoadingDbs ? (
          <p className="loading-text">Loading databases…</p>
        ) : (
          <DatabaseSelector
            databases={databases}
            selected={selectedDb}
            onSelect={setSelectedDb}
            disabled={isQuerying}
          />
        )}

        <QueryInput
          onSubmit={handleQuery}
          disabled={isQuerying || !selectedDb}
          placeholder="e.g. How many products are in the catalog?"
        />

        {isQuerying && <p className="loading-text">Running query…</p>}

        {error && <div className="error-banner">{error}</div>}

        {response && (
          <div className="results-section">
            <AuditBadge
              blocked={response.blocked}
              riskLevel={response.risk_level}
              blockReason={response.block_reason}
              guardrailPassed={response.guardrail_passed}
            />
            <SqlPreview sql={response.generated_sql} />
            <ResultsTable results={response.results} rowCount={response.row_count} />
          </div>
        )}
      </main>
    </div>
  )
}
