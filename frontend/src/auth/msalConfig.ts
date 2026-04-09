import { PublicClientApplication } from '@azure/msal-browser'
import type { Configuration, PopupRequest, SilentRequest } from '@azure/msal-browser'

export const isDemoMode: boolean = import.meta.env.VITE_DEMO_MODE === 'true'

const clientId: string =
  (import.meta.env.VITE_CLIENT_ID as string | undefined) || '00000000-0000-0000-0000-000000000000'
const tenantId: string =
  (import.meta.env.VITE_TENANT_ID as string | undefined) || 'common'

export const msalConfig: Configuration = {
  auth: {
    clientId,
    authority: `https://login.microsoftonline.com/${tenantId}`,
    redirectUri: window.location.origin,
  },
  cache: {
    cacheLocation: 'sessionStorage',
  },
}

export const loginRequest: PopupRequest = {
  scopes: ['openid', 'profile', 'email'],
}

const defaultApiScope: string =
  (import.meta.env.VITE_API_SCOPE as string | undefined) || ''

export const apiRequest = (scope: string): SilentRequest => ({
  scopes: [scope || defaultApiScope],
})

export const msalInstance = new PublicClientApplication(msalConfig)
