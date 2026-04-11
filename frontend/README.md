# Frontend — InRiver DataCase Chat UI

React SPA with custom login, chat interface, and database indicator.

## Stack

React 19 · TypeScript · Vite · Tailwind CSS v4 · Zustand

## Run

```bash
npm install
cp .env.example .env
npm run dev          # http://localhost:5173
```

## Build

```bash
npm run build        # production build → dist/
```

## Test

```bash
npx vitest run       # full suite (12 tests)
npx vitest run src/api/   # tests in a directory
```

## Architecture

```
src/
  auth/
    LoginForm.tsx      Email/password login form
    AuthContext.tsx     Auth state provider (tokens in memory, NOT localStorage)
    useAuth.ts         Auth hook
  api/
    client.ts          fetch-based API client (no axios), auto token refresh
  components/
    ChatWindow.tsx     Scrollable message list
    MessageBubble.tsx  User/assistant messages with collapsible SQL detail
    QueryInput.tsx     Text input with Enter-to-send
    ResultsTable.tsx   Data table for query results
    Header.tsx         App header with logout
    DatabaseBadge.tsx  Read-only database indicator
  store/
    chatStore.ts       Zustand store for chat state
  types/
    index.ts           TypeScript interfaces
```

## Key Design Decisions

- **No MSAL** — custom JWT auth via backend API
- **Tokens in memory** — stored in React context/closure, never localStorage
- **No axios** — uses native `fetch` with auto 401 → token refresh
- **Zustand** — lightweight state management for chat messages
- **Tailwind CSS v4** — via `@tailwindcss/vite` plugin
- **Nginx** — serves production build with SPA routing (`try_files $uri /index.html`)
