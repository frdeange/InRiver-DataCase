# frontend/

React + TypeScript + Vite frontend for the InRiver Agentic SQL PoC.

## Structure

```
frontend/
├── src/
│   ├── main.tsx             # App entry point, MSAL provider wrapper
│   ├── App.tsx              # Root component, routing
│   ├── auth/                # MSAL configuration and auth hooks
│   │   ├── msalConfig.ts    # MSAL PublicClientApplication config (client ID, tenant, scopes)
│   │   └── useAuth.ts       # Hook: current user, login/logout, getAccessToken()
│   ├── components/          # Reusable UI components
│   │   ├── QueryInput.tsx   # Natural language query text area + submit button
│   │   ├── SqlPreview.tsx   # Displays the AI-generated SQL (read-only code block)
│   │   ├── ResultsTable.tsx # Renders query results as a sortable table
│   │   ├── AuditBadge.tsx   # Shows guardrail decision (ALLOWED/BLOCKED + reason)
│   │   └── DatabaseSelector.tsx # Dropdown of user's permitted databases
│   ├── pages/               # Route-level components
│   │   ├── LoginPage.tsx    # Shown to unauthenticated users; triggers MSAL redirect
│   │   ├── QueryPage.tsx    # Main query interface (requires auth)
│   │   └── NotFoundPage.tsx # 404
│   └── api/                 # API client functions
│       └── queryApi.ts      # Typed fetch wrapper for POST /api/query, GET /api/databases
├── index.html
├── package.json
├── tsconfig.json
└── vite.config.ts
```

## Local Development

```bash
cd frontend
npm install
cp .env.example .env.local   # Fill in VITE_CLIENT_ID, VITE_TENANT_ID, VITE_API_URL
npm run dev                   # Vite dev server on http://localhost:5173
```

The Vite dev server proxies `/api/*` to `http://localhost:8000` to avoid CORS issues during local development. See `vite.config.ts`.

## Environment Variables

| Variable | Description |
|----------|-------------|
| `VITE_CLIENT_ID` | Entra ID App Registration client ID |
| `VITE_TENANT_ID` | Entra ID tenant ID |
| `VITE_API_URL` | Backend API base URL (empty in dev — uses Vite proxy) |
| `VITE_API_SCOPE` | OAuth2 scope for backend API (e.g., `api://<client-id>/query.read`) |

## Auth Flow

1. Unauthenticated users are redirected to `LoginPage` which calls `msalInstance.loginRedirect()`.
2. After Entra ID login, MSAL stores the access token in session storage.
3. `useAuth.ts` provides `getAccessToken()` which silently refreshes the token as needed.
4. All API calls include `Authorization: Bearer <token>` from `getAccessToken()`.

## Build

```bash
npm run build   # Output to dist/
```

The `Dockerfile` in this directory serves the built static files via nginx.
