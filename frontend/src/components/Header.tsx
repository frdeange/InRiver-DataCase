import { useAuth } from "../auth/useAuth";
import DatabaseSelector from "./DatabaseSelector";

export default function Header() {
  const { user, logout } = useAuth();

  return (
    <header className="flex items-center justify-between bg-blue-700 px-6 py-3 text-white shadow-md">
      <div className="flex items-center gap-3">
        <h1 className="text-xl font-bold tracking-tight">InRiver DataCase</h1>
      </div>

      <div className="flex items-center gap-4">
        <DatabaseSelector />

        {user && (
          <span className="hidden text-sm text-blue-100 sm:inline">
            {user.name}
          </span>
        )}

        <button
          onClick={logout}
          className="rounded border border-blue-400 px-3 py-1 text-sm transition hover:bg-blue-600"
        >
          Sign out
        </button>
      </div>
    </header>
  );
}
