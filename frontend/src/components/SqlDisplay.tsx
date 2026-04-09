import { useState } from "react";

interface SqlDisplayProps {
  sql: string;
}

export default function SqlDisplay({ sql }: SqlDisplayProps) {
  const [copied, setCopied] = useState(false);
  const [collapsed, setCollapsed] = useState(false);

  const handleCopy = async () => {
    await navigator.clipboard.writeText(sql);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="rounded-lg overflow-hidden border border-gray-700 mt-2">
      <div className="flex items-center justify-between bg-gray-800 px-4 py-2">
        <span className="text-xs font-mono text-gray-400 uppercase tracking-wider">SQL</span>
        <div className="flex items-center gap-2">
          <button
            onClick={handleCopy}
            className="text-xs text-gray-400 hover:text-white transition-colors flex items-center gap-1 focus:outline-none focus:ring-1 focus:ring-gray-500 rounded px-1"
            aria-label="Copy SQL to clipboard"
          >
            {copied ? (
              <>
                <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
                Copied!
              </>
            ) : (
              <>
                <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
                Copy
              </>
            )}
          </button>
          <button
            onClick={() => setCollapsed((c) => !c)}
            className="text-xs text-gray-400 hover:text-white transition-colors focus:outline-none focus:ring-1 focus:ring-gray-500 rounded px-1"
            aria-label={collapsed ? "Expand SQL" : "Collapse SQL"}
          >
            {collapsed ? "▼ Show" : "▲ Hide"}
          </button>
        </div>
      </div>
      {!collapsed && (
        <pre className="bg-gray-900 text-green-300 text-sm font-mono p-4 overflow-x-auto whitespace-pre-wrap break-all">
          {sql}
        </pre>
      )}
    </div>
  );
}
