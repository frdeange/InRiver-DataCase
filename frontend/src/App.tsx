import { useEffect } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { MsalProvider, AuthenticatedTemplate, UnauthenticatedTemplate } from "@azure/msal-react";
import { PublicClientApplication } from "@azure/msal-browser";
import { msalConfig } from "./auth/msalConfig";
import { setTokenGetter } from "./api/client";
import { useAuthToken } from "./auth/useAuthToken";
import LoginPage from "./components/LoginPage";
import Layout from "./components/Layout";
import ChatInterface from "./components/ChatInterface";

const msalInstance = new PublicClientApplication(msalConfig);

function TokenSetter() {
  const { getToken } = useAuthToken();
  useEffect(() => {
    setTokenGetter(getToken);
  }, [getToken]);
  return null;
}

function AppRoutes() {
  return (
    <>
      <TokenSetter />
      <AuthenticatedTemplate>
        <Routes>
          <Route path="/" element={<Navigate to="/chat" replace />} />
          <Route path="/login" element={<Navigate to="/chat" replace />} />
          <Route
            path="/chat"
            element={
              <Layout>
                <ChatInterface />
              </Layout>
            }
          />
          <Route path="*" element={<Navigate to="/chat" replace />} />
        </Routes>
      </AuthenticatedTemplate>
      <UnauthenticatedTemplate>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </UnauthenticatedTemplate>
    </>
  );
}

export default function App() {
  return (
    <MsalProvider instance={msalInstance}>
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
    </MsalProvider>
  );
}
