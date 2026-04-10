import { Configuration } from "@azure/msal-browser";

export const msalConfig: Configuration = {
  auth: {
    clientId: import.meta.env.VITE_AZURE_CLIENT_ID || "",
    authority: import.meta.env.VITE_AZURE_AUTHORITY || "",
    redirectUri: window.location.origin,
  },
  cache: {
    cacheLocation: "sessionStorage",
  },
};

export const loginRequest = {
  scopes: [import.meta.env.VITE_API_SCOPE || ""],
};

export const apiScope = import.meta.env.VITE_API_SCOPE || "";
