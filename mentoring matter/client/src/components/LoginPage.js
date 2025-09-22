import React, { useState } from 'react';
import axios from 'axios';

const LoginPage = ({ onLogin }) => {
  const [isLogin, setIsLogin] = useState(true);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    role: 'mentee',
    organization: ''
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const url = `/api/auth/${isLogin ? 'login' : 'register'}`;
      const response = await axios.post(url, formData);
      
      onLogin(response.data.token, response.data.user);
    } catch (err) {
      setError(err.response?.data?.message || 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-card">
        <h2>Mentoring Matters</h2>
        <div className="auth-tabs">
          <button 
            className={isLogin ? 'active' : ''} 
            onClick={() => setIsLogin(true)}
          >
            Login
          </button>
          <button 
            className={!isLogin ? 'active' : ''} 
            onClick={() => setIsLogin(false)}
          >
            Sign Up
          </button>
        </div>

        <form onSubmit={handleSubmit} className="auth-form">
          {!isLogin && (
            <input
              type="text"
              name="name"
              placeholder="Full Name"
              value={formData.name}
              onChange={handleChange}
              required
            />
          )}
          
          <input
            type="email"
            name="email"
            placeholder="Email"
            value={formData.email}
            onChange={handleChange}
            required
          />
          
          <input
            type="password"
            name="password"
            placeholder="Password"
            value={formData.password}
            onChange={handleChange}
            required
          />

          {!isLogin && (
            <>
              <select
                name="role"
                value={formData.role}
                onChange={handleChange}
                required
              >
                <option value="mentee">Mentee</option>
                <option value="mentor">Mentor</option>
                <option value="admin">Admin</option>
              </select>

              <input
                type="text"
                name="organization"
                placeholder="Organization"
                value={formData.organization}
                onChange={handleChange}
                required
              />
            </>
          )}

          {error && <div className="error">{error}</div>}

          <button type="submit" disabled={loading} className="auth-btn">
            {loading ? 'Please wait...' : (isLogin ? 'Login' : 'Sign Up')}
          </button>
        </form>
      </div>
    </div>
  );
};

export default LoginPage;
