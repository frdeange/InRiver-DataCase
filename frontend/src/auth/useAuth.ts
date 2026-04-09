import { useState, useCallback } from 'react'
import { useMsal } from '@azure/msal-react'
import { InteractionStatus } from '@azure/msal-browser'
import { isDemoMode, loginRequest, apiRequest, msalInstance } from './msalConfig'

export interface AuthState {
  user: string | null
  isAuthenticated: boolean
  login: () => void
  logout: () => void
  getAccessToken: () => Promise<string | null>
  isLoading: boolean
}

const DEMO_USERS = ['alice@demo.com', 'bob@demo.com', 'admin@demo.com']
const DEMO_USER_KEY = 'demo_user'

function useDemoAuth(): AuthState {
  const [user, setUser] = useState<string | null>(() => {
    return localStorage.getItem(DEMO_USER_KEY)
  })

  const login = useCallback(() => {
    const stored = localStorage.getItem(DEMO_USER_KEY) ?? DEMO_USERS[0]
    localStorage.setItem(DEMO_USER_KEY, stored)
    setUser(stored)
  }, [])

  const logout = useCallback(() => {
    localStorage.removeItem(DEMO_USER_KEY)
    setUser(null)
  }, [])

  const getAccessToken = useCallback(async (): Promise<string | null> => {
    return null
  }, [])

  return {
    user,
    isAuthenticated: user !== null,
    login,
    logout,
    getAccessToken,
    isLoading: false,
  }
}

function useMsalAuth(): AuthState {
  const { instance, accounts, inProgress } = useMsal()
  const account = accounts[0] ?? null
  const user = account?.username ?? null
  const apiScope = (import.meta.env.VITE_API_SCOPE as string | undefined) ?? ''

  const login = useCallback(() => {
    instance.loginPopup(loginRequest).catch(console.error)
  }, [instance])

  const logout = useCallback(() => {
    instance.logoutPopup().catch(console.error)
  }, [instance])

  const getAccessToken = useCallback(async (): Promise<string | null> => {
    if (!account) return null
    try {
      const response = await instance.acquireTokenSilent({
        ...apiRequest(apiScope),
        account,
      })
      return response.accessToken
    } catch {
      return null
    }
  }, [instance, account, apiScope])

  return {
    user,
    isAuthenticated: !!account,
    login,
    logout,
    getAccessToken,
    isLoading: inProgress !== InteractionStatus.None,
  }
}

export const useAuth: () => AuthState = isDemoMode ? useDemoAuth : useMsalAuth
export { DEMO_USERS, DEMO_USER_KEY }
export { msalInstance }
