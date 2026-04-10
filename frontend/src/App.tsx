import {
  AuthenticatedTemplate,
  UnauthenticatedTemplate,
} from "@azure/msal-react";
import { useAuth } from "./auth/useAuth";
import Header from "./components/Header";
import ChatWindow from "./components/ChatWindow";
import QueryInput from "./components/QueryInput";

export default function App() {
  const { login } = useAuth();

  return (
    <div className="flex h-full flex-col bg-gray-50">
      <AuthenticatedTemplate>
        <Header />
        <main className="flex flex-1 flex-col overflow-hidden">
          <ChatWindow />
          <QueryInput />
        </main>
      </AuthenticatedTemplate>

      <UnauthenticatedTemplate>
        <div className="flex h-full items-center justify-center">
          <div className="text-center">
            <h1 className="mb-4 text-3xl font-bold text-gray-800">
              InRiver DataCase
            </h1>
            <p className="mb-8 text-gray-600">
              Sign in to query your databases using natural language.
            </p>
            <button
              onClick={login}
              className="rounded-lg bg-blue-700 px-8 py-3 text-lg font-semibold text-white shadow-md transition hover:bg-blue-800"
            >
              Sign in with Microsoft
            </button>
          </div>
        </div>
      </UnauthenticatedTemplate>
    </div>
  );
}
