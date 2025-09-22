
import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import axios from 'axios';
import './App.css';

// Components
import LoginPage from './components/LoginPage';
import Dashboard from './components/Dashboard';
import Sidebar from './components/Sidebar';

// Set default axios base URL
axios.defaults.baseURL = 'http://localhost:5000';

function App() {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(localStorage.getItem('token'));
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (token) {
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
      // In a real app, you'd verify the token with the server
      // For now, decode the token to get user info
      try {
        const payload = JSON.parse(atob(token.split('.')[1]));
        setUser({ id: payload.id, role: payload.role, organization: payload.organization });
      } catch (err) {
        localStorage.removeItem('token');
        setToken(null);
      }
    }
    setLoading(false);
  }, [token]);

  const login = (authToken, userData) => {
    localStorage.setItem('token', authToken);
    setToken(authToken);
    setUser(userData);
    axios.defaults.headers.common['Authorization'] = `Bearer ${authToken}`;
  };

  const logout = () => {
    localStorage.removeItem('token');
    setToken(null);
    setUser(null);
    delete axios.defaults.headers.common['Authorization'];
  };

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  if (!user) {
    return <LoginPage onLogin={login} />;
  }

  return (
    <Router>
      <div className="app-layout">
        <Sidebar user={user} onLogout={logout} />
        <main className="main-content">
          <Routes>
            <Route path="/" element={<Dashboard user={user} />} />
            <Route path="/account" element={<Navigate to="/" />} />
            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;
