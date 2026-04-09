import { useState } from 'react'

interface QueryInputProps {
  onSubmit: (question: string) => void
  disabled?: boolean
  placeholder?: string
}

export default function QueryInput({
  onSubmit,
  disabled = false,
  placeholder = 'Ask a question about your data...',
}: QueryInputProps) {
  const [question, setQuestion] = useState('')

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    const trimmed = question.trim()
    if (!trimmed) return
    onSubmit(trimmed)
  }

  return (
    <form className="query-form" onSubmit={handleSubmit}>
      <label htmlFor="question-input" className="field-label">
        Question
      </label>
      <textarea
        id="question-input"
        className="textarea"
        rows={3}
        value={question}
        onChange={(e) => setQuestion(e.target.value)}
        placeholder={placeholder}
        disabled={disabled}
      />
      <button type="submit" className="btn btn-primary" disabled={disabled || !question.trim()}>
        {disabled ? 'Running…' : 'Run Query'}
      </button>
    </form>
  )
}
