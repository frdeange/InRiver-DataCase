import { useState } from 'react';
import Markdown from 'react-markdown';
import type { ChatMessage } from '../types';
import { ResultsTable } from './ResultsTable';

interface MessageBubbleProps {
  message: ChatMessage;
}

export function MessageBubble({ message }: MessageBubbleProps) {
  const [showSql, setShowSql] = useState(false);
  const isUser = message.role === 'user';

  return (
    <div className={`flex ${isUser ? 'justify-end' : 'justify-start'} mb-4`}>
      <div
        className={`max-w-[85%] md:max-w-[70%] ${
          isUser
            ? 'bg-indigo-600 text-white rounded-2xl rounded-br-md'
            : message.error
              ? 'bg-white border-2 border-red-200 rounded-2xl rounded-bl-md'
              : 'bg-white border border-gray-200 rounded-2xl rounded-bl-md shadow-sm'
        } px-4 py-3`}
      >
        {/* Loading state */}
        {message.isLoading && (
          <div className="flex items-center gap-1.5 py-1">
            <span className="w-2 h-2 bg-indigo-400 rounded-full animate-bounce [animation-delay:-0.3s]" />
            <span className="w-2 h-2 bg-indigo-400 rounded-full animate-bounce [animation-delay:-0.15s]" />
            <span className="w-2 h-2 bg-indigo-400 rounded-full animate-bounce" />
          </div>
        )}

        {/* Content */}
        {!message.isLoading && (
          <>
            {message.error && (
              <div className="text-red-600 text-sm mb-1 font-medium">Error: {message.error}</div>
            )}
            {isUser ? (
              <p className="text-sm leading-relaxed whitespace-pre-wrap">{message.content}</p>
            ) : (
              <div className="text-sm leading-relaxed text-gray-800 prose prose-sm max-w-none prose-p:my-1 prose-ul:my-1 prose-li:my-0 prose-headings:my-2 prose-pre:bg-gray-900 prose-pre:text-gray-100">
                <Markdown>{message.content}</Markdown>
              </div>
            )}

            {/* SQL collapsible */}
            {message.sql && (
              <div className="mt-2">
                <button
                  onClick={() => setShowSql(!showSql)}
                  className="flex items-center gap-1 text-xs text-gray-500 hover:text-gray-700 transition-colors"
                >
                  <svg
                    className={`w-3.5 h-3.5 transition-transform ${showSql ? 'rotate-90' : ''}`}
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    strokeWidth={2}
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                  </svg>
                  SQL Query
                  {message.execution_time_ms != null && (
                    <span className="text-gray-400 ml-1">({message.execution_time_ms}ms)</span>
                  )}
                </button>
                {showSql && (
                  <pre className="mt-2 p-3 rounded-lg bg-gray-900 text-gray-100 text-xs overflow-x-auto font-mono">
                    {message.sql}
                  </pre>
                )}
              </div>
            )}

            {/* Results table */}
            {message.columns && message.rows && message.columns.length > 0 && (
              <ResultsTable columns={message.columns} rows={message.rows} />
            )}

            {/* Timestamp */}
            <div className={`text-[10px] mt-1.5 ${isUser ? 'text-indigo-200' : 'text-gray-400'}`}>
              {message.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
            </div>
          </>
        )}
      </div>
    </div>
  );
}
