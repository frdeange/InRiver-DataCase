import { useMsal } from "@azure/msal-react";
import { AccountInfo, InteractionRequiredAuthError } from "@azure/msal-browser";
import { loginRequest } from "./msalConfig";

export function useAuthToken(): { getToken: () => Promise<string>; account: AccountInfo | null } {
  const { instance, accounts } = useMsal();
  const account = accounts[0] ?? null;

  const getToken = async (): Promise<string> => {
    if (!account) throw new Error("No account found");
    try {
      const response = await instance.acquireTokenSilent({
        ...loginRequest,
        account,
      });
      return response.accessToken;
    } catch (error) {
      if (error instanceof InteractionRequiredAuthError) {
        await instance.acquireTokenRedirect({ ...loginRequest, account });
        throw error;
      }
      throw error;
    }
  };

  return { getToken, account };
}
