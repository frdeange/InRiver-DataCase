import { Navigate, Route, Routes, BrowserRouter } from 'react-router-dom'
import { MsalProvider } from '@azure/msal-react'
import { isDemoMode, msalInstance } from './auth/msalConfig'
import { useAuth } from './auth/useAuth'
import QueryPage from './pages/QueryPage'
import LoginPage from './pages/LoginPage'
import NotFoundPage from './pages/NotFoundPage'

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth()
  if (isLoading) return <p className="loading-text">Loading…</p>
  return isAuthenticated ? <>{children}</> : <Navigate to="/login" replace />
}

function AppRoutes() {
  return (
    <BrowserRouter>
      <Routes>
        <Route
          path="/"
          element={
            <ProtectedRoute>
              <QueryPage />
            </ProtectedRoute>
          }
        />
        <Route path="/login" element={<LoginPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </BrowserRouter>
  )
}

export default function App() {
  if (isDemoMode) {
    return <AppRoutes />
  }
  return (
    <MsalProvider instance={msalInstance}>
      <AppRoutes />
    </MsalProvider>
  )
}
