# InRiver DataCase — Frontend

React + TypeScript + Vite SPA for querying InRiver product databases using natural language.

## Stack

- **React 18** + **TypeScript**
- **Vite** (dev server + build)
- **MSAL** (`@azure/msal-browser` / `@azure/msal-react`) — Azure AD auth
- **Axios** — API client with Bearer token interceptor
- **React Router v6** — client-side routing
- **Tailwind CSS** — utility-first styling

## Development

```bash
cp .env.example .env
# Fill in your Azure AD values in .env

npm install
npm run dev       # → http://localhost:5173
```

## Environment Variables

| Variable | Description |
|---|---|
| `VITE_AZURE_CLIENT_ID` | Azure AD app registration client ID |
| `VITE_AZURE_TENANT_ID` | Azure AD tenant ID |
| `VITE_REDIRECT_URI` | OAuth redirect URI (default: `http://localhost:3000`) |
| `VITE_API_BASE_URL` | Backend API base URL (default: `http://localhost:8000`) |

## Build

```bash
npm run build     # outputs to dist/
```

## Docker

```bash
docker build -t inriver-datacase-frontend .
docker run -p 80:80 inriver-datacase-frontend
```
