import React from 'react';
import { AuthProvider, useAuth } from './AuthContext';
import { Auth } from './auth';
import { Dashboard } from './Dashboard';
import { LoadingSkeleton } from './components/LoadingSkeleton';

function AppContent() {
  const { user, loading } = useAuth();

  if (loading) {
    return <LoadingSkeleton type="app" />;
  }

  if (!user) {
    return <Auth />;
  }

  return (
    <Dashboard />
  );
}

function App() {
  return (
    <AuthProvider>
      <style>{`
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
        
        * {
          box-sizing: border-box;
        }
        
        body {
          margin: 0;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
            'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
            sans-serif;
          -webkit-font-smoothing: antialiased;
          -moz-osx-font-smoothing: grayscale;
        }
      `}</style>
      <AppContent />
    </AuthProvider>
  );
}

export default App;