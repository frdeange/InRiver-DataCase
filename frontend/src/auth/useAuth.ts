import { useMsal } from "@azure/msal-react";
import { InteractionRequiredAuthError } from "@azure/msal-browser";
import { loginRequest, apiScope } from "./msalConfig";

export function useAuth() {
  const { instance, accounts } = useMsal();
  const account = accounts[0] ?? null;

  const isAuthenticated = accounts.length > 0;

  const user = account
    ? {
        name: account.name ?? "Unknown",
        email: account.username ?? "",
      }
    : null;

  async function acquireToken(): Promise<string> {
    if (!account) throw new Error("No authenticated account");

    try {
      const response = await instance.acquireTokenSilent({
        scopes: [apiScope],
        account,
      });
      return response.accessToken;
    } catch (error) {
      if (error instanceof InteractionRequiredAuthError) {
        await instance.acquireTokenRedirect({ scopes: [apiScope] });
        throw new Error("Redirecting for authentication...");
      }
      throw error;
    }
  }

  function login() {
    instance.loginRedirect(loginRequest);
  }

  function logout() {
    instance.logoutRedirect({ postLogoutRedirectUri: window.location.origin });
  }

  return { isAuthenticated, user, acquireToken, login, logout };
}
