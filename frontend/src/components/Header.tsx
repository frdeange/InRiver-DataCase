import { useAuth } from '../auth/useAuth';
import { DatabaseBadge } from './DatabaseBadge';

export function Header() {
  const { user, databases, logout } = useAuth();

  return (
    <header className="bg-white border-b border-gray-200 px-4 py-3 flex items-center justify-between shrink-0">
      <div className="flex items-center gap-3">
        <div className="flex items-center justify-center w-9 h-9 rounded-lg bg-indigo-600">
          <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4" />
          </svg>
        </div>
        <h1 className="text-lg font-semibold text-gray-900">InRiver DataCase</h1>
        <DatabaseBadge databases={databases} />
      </div>

      <div className="flex items-center gap-4">
        {user && (
          <span className="text-sm text-gray-600 hidden sm:inline">
            {user.email}
          </span>
        )}
        <button
          onClick={logout}
          className="text-sm text-gray-500 hover:text-gray-800 px-3 py-1.5 rounded-lg hover:bg-gray-100 transition-colors"
        >
          Sign out
        </button>
      </div>
    </header>
  );
}
