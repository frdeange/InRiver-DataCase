import { useState, useRef, useEffect } from "react"
import type { KeyboardEvent } from "react"
import { postQuery } from "../api/queries"
import type { QueryResult } from "../api/queries"
import { fetchDatabases } from "../api/queryApi"
import DatabaseSelector from "./DatabaseSelector"
import SqlDisplay from "./SqlDisplay"
import ResultsTable from "./ResultsTable"

interface Message {
  id: string
  type: "user" | "assistant" | "error"
  content: string
  result?: QueryResult
}

export default function ChatInterface() {
  const [databases, setDatabases] = useState<string[]>([])
  const [selectedDb, setSelectedDb] = useState<string | null>(null)
  const [messages, setMessages] = useState<Message[]>([])
  const [input, setInput] = useState("")
  const [loading, setLoading] = useState(false)
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    fetchDatabases("", null)
      .then((res) => {
        setDatabases(res.databases)
        if (res.databases.length > 0) setSelectedDb(res.databases[0])
      })
      .catch(console.error)
  }, [])

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" })
  }, [messages, loading])

  const handleSend = async () => {
    const question = input.trim()
    if (!question || !selectedDb || loading) return

    const userMsg: Message = {
      id: `user-${Date.now()}`,
      type: "user",
      content: question,
    }
    setMessages((prev) => [...prev, userMsg])
    setInput("")
    setLoading(true)

    try {
      const result = await postQuery({ question, customer_db: selectedDb })
      setMessages((prev) => [
        ...prev,
        { id: `assistant-${Date.now()}`, type: "assistant", content: result.explanation, result },
      ])
    } catch (err) {
      const detail = err instanceof Error ? err.message : "An unexpected error occurred."
      setMessages((prev) => [
        ...prev,
        { id: `error-${Date.now()}`, type: "error", content: detail },
      ])
    } finally {
      setLoading(false)
    }
  }

  const handleKeyDown = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault()
      void handleSend()
    }
  }

  return (
    <div>
      <DatabaseSelector
        databases={databases}
        selected={selectedDb}
        onSelect={setSelectedDb}
        disabled={loading}
      />
      <div>
        {messages.map((msg) => {
          if (msg.type === "error") {
            return <div key={msg.id} className="error-banner">{msg.content}</div>
          }
          return (
            <div key={msg.id}>
              <p>{msg.content}</p>
              {msg.result && (
                <>
                  <SqlDisplay sql={msg.result.sql} />
                  <ResultsTable results={msg.result.results} rowCount={msg.result.row_count} />
                </>
              )}
            </div>
          )
        })}
        {loading && <p className="loading-text">Thinking…</p>}
        <div ref={bottomRef} />
      </div>
      <div>
        <textarea
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="Ask a question…"
          rows={3}
          disabled={loading || !selectedDb}
          className="textarea"
        />
        <button
          onClick={() => void handleSend()}
          disabled={loading || !input.trim() || !selectedDb}
          className="btn btn-primary"
        >
          Send
        </button>
      </div>
    </div>
  )
}
