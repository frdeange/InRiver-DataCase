import { AuthProvider } from './auth/AuthContext';
import { useAuth } from './auth/useAuth';
import { LoginForm } from './auth/LoginForm';
import { Header } from './components/Header';
import { ChatWindow } from './components/ChatWindow';
import { QueryInput } from './components/QueryInput';

function AuthenticatedApp() {
  const { isAuthenticated } = useAuth();

  if (!isAuthenticated) {
    return <LoginForm />;
  }

  return (
    <div className="h-screen flex flex-col bg-gray-50">
      <Header />
      <ChatWindow />
      <QueryInput />
    </div>
  );
}

function App() {
  return (
    <AuthProvider>
      <AuthenticatedApp />
    </AuthProvider>
  );
}

export default App;
