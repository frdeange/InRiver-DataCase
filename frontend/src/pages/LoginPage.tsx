import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth, DEMO_USERS, DEMO_USER_KEY } from '../auth/useAuth'
import { isDemoMode } from '../auth/msalConfig'

export default function LoginPage() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const [selectedUser, setSelectedUser] = useState<string>(
    localStorage.getItem(DEMO_USER_KEY) ?? DEMO_USERS[0],
  )

  const handleDemoLogin = (e: React.FormEvent) => {
    e.preventDefault()
    localStorage.setItem(DEMO_USER_KEY, selectedUser)
    login()
    navigate('/')
  }

  if (isDemoMode) {
    return (
      <div className="login-page">
        <div className="login-card">
          <h1 className="login-title">InRiver Agentic SQL Demo</h1>
          <p className="login-subtitle">Select a demo user to continue</p>
          <form onSubmit={handleDemoLogin} className="login-form">
            <label htmlFor="demo-user" className="field-label">
              Demo User
            </label>
            <select
              id="demo-user"
              className="select"
              value={selectedUser}
              onChange={(e) => setSelectedUser(e.target.value)}
            >
              {DEMO_USERS.map((u) => (
                <option key={u} value={u}>
                  {u}
                </option>
              ))}
            </select>
            <button type="submit" className="btn btn-primary btn-full">
              Sign In (Demo)
            </button>
          </form>
        </div>
      </div>
    )
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <h1 className="login-title">InRiver Agentic SQL Demo</h1>
        <p className="login-subtitle">Sign in with your Microsoft account to continue</p>
        <button className="btn btn-primary btn-full" onClick={login}>
          Sign in with Microsoft
        </button>
      </div>
    </div>
  )
}
