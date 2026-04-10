import { type ChatMessage } from "../store/chatStore";
import ResultsTable from "./ResultsTable";

interface Props {
  message: ChatMessage;
}

export default function MessageBubble({ message }: Props) {
  const isUser = message.role === "user";
  const isError = message.role === "error";

  return (
    <div className={`flex ${isUser ? "justify-end" : "justify-start"}`}>
      <div
        className={`max-w-[85%] rounded-2xl px-4 py-3 shadow-sm ${
          isUser
            ? "bg-blue-600 text-white"
            : isError
              ? "border border-red-300 bg-red-50 text-red-800"
              : "bg-white text-gray-800 ring-1 ring-gray-200"
        }`}
      >
        <p className="whitespace-pre-wrap text-sm leading-relaxed">
          {message.content}
        </p>

        {message.sql && (
          <details className="mt-3 border-t border-gray-200 pt-2">
            <summary className="cursor-pointer text-xs font-medium text-gray-500 hover:text-gray-700">
              View generated SQL
            </summary>
            <pre className="mt-2 overflow-x-auto rounded bg-gray-100 p-2 text-xs text-gray-700">
              <code>{message.sql}</code>
            </pre>
          </details>
        )}

        {message.columns && message.rows && message.rows.length > 0 && (
          <div className="mt-3">
            <ResultsTable
              columns={message.columns}
              rows={message.rows}
              rowCount={message.rowCount ?? message.rows.length}
            />
          </div>
        )}

        {message.executionTimeMs !== undefined && (
          <p className="mt-2 text-right text-xs text-gray-400">
            {message.executionTimeMs}ms
          </p>
        )}
      </div>
    </div>
  );
}
