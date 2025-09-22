import React, { useState } from 'react';
import { useAuth } from './AuthContext';

export function Auth() {
  const { signIn, signUp } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [role, setRole] = useState('mentee');
  const [isSignUp, setIsSignUp] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      if (isSignUp) {
        await signUp(email, password, fullName, role);
      } else {
        await signIn(email, password);
        // Don't wait here - let auth state change handle the rest
      }
    } catch (error: any) {
      setError(error.message);
      setLoading(false); // Only stop loading on error
    }
    // Don't set loading to false here - let AuthContext handle it
  };

  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      alignItems: 'center', 
      justifyContent: 'center',
      background: 'linear-gradient(135deg, #e6f3ff 0%, #cce7ff 100%)'
    }}>
      <div style={{ 
        maxWidth: 400, 
        width: '100%',
        margin: '0 20px',
        padding: 32, 
        background: 'white', 
        borderRadius: 12,
        boxShadow: '0 4px 20px rgba(0,0,0,0.1)'
      }}>
        <h1 style={{ 
          textAlign: 'center', 
          color: '#1e40af', 
          marginBottom: 8,
          fontSize: 28,
          fontWeight: 'bold'
        }}>
          Mentoring Matters
        </h1>
        <p style={{ 
          textAlign: 'center', 
          color: '#64748b', 
          marginBottom: 32,
          fontSize: 14
        }}>
          {isSignUp ? 'Create your account' : 'Sign in to your account'}
        </p>
        
        <form onSubmit={handleSubmit}>
          {isSignUp && (
            <div style={{ marginBottom: 16 }}>
              <label style={{ display: 'block', marginBottom: 4, color: '#374151', fontSize: 14, fontWeight: 500 }}>
                Full Name
              </label>
              <input 
                type="text" 
                placeholder="Enter your full name" 
                value={fullName} 
                onChange={e => setFullName(e.target.value)} 
                required 
                style={{ 
                  width: '100%', 
                  padding: 12,
                  border: '1px solid #d1d5db',
                  borderRadius: 6,
                  fontSize: 14,
                  outline: 'none',
                  transition: 'border-color 0.2s'
                }}
                onFocus={e => e.target.style.borderColor = '#3b82f6'}
                onBlur={e => e.target.style.borderColor = '#d1d5db'}
              />
            </div>
          )}
          
          <div style={{ marginBottom: 16 }}>
            <label style={{ display: 'block', marginBottom: 4, color: '#374151', fontSize: 14, fontWeight: 500 }}>
              Email
            </label>
            <input 
              type="email" 
              placeholder="Enter your email" 
              value={email} 
              onChange={e => setEmail(e.target.value)} 
              required 
              style={{ 
                width: '100%', 
                padding: 12,
                border: '1px solid #d1d5db',
                borderRadius: 6,
                fontSize: 14,
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={e => e.target.style.borderColor = '#3b82f6'}
              onBlur={e => e.target.style.borderColor = '#d1d5db'}
            />
          </div>
          
          <div style={{ marginBottom: isSignUp ? 16 : 24 }}>
            <label style={{ display: 'block', marginBottom: 4, color: '#374151', fontSize: 14, fontWeight: 500 }}>
              Password
            </label>
            <input 
              type="password" 
              placeholder="Enter your password" 
              value={password} 
              onChange={e => setPassword(e.target.value)} 
              required 
              style={{ 
                width: '100%', 
                padding: 12,
                border: '1px solid #d1d5db',
                borderRadius: 6,
                fontSize: 14,
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={e => e.target.style.borderColor = '#3b82f6'}
              onBlur={e => e.target.style.borderColor = '#d1d5db'}
            />
          </div>

          {isSignUp && (
            <div style={{ marginBottom: 24 }}>
              <label style={{ display: 'block', marginBottom: 4, color: '#374151', fontSize: 14, fontWeight: 500 }}>
                Role
              </label>
              <select 
                value={role} 
                onChange={e => setRole(e.target.value)}
                style={{ 
                  width: '100%', 
                  padding: 12,
                  border: '1px solid #d1d5db',
                  borderRadius: 6,
                  fontSize: 14,
                  outline: 'none',
                  background: 'white'
                }}
              >
                <option value="mentee">Mentee</option>
                <option value="mentor">Mentor</option>
                <option value="admin">Admin</option>
              </select>
            </div>
          )}
          
          <button 
            type="submit" 
            disabled={loading}
            style={{ 
              width: '100%',
              padding: 12,
              background: loading ? '#10b981' : '#3b82f6',
              color: 'white',
              border: 'none',
              borderRadius: 6,
              fontSize: 14,
              fontWeight: 500,
              cursor: loading ? 'not-allowed' : 'pointer',
              transition: 'all 0.2s',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 8
            }}
          >
            {loading ? 
              <>{isSignUp ? '✓ Creating Account...' : '✓ Signing In...'}</> : 
              <>{isSignUp ? 'Create Account' : 'Sign In'}</>
            }
          </button>
        </form>
        
        {error && (
          <div style={{ 
            color: '#ef4444', 
            marginTop: 16,
            padding: 12,
            background: '#fef2f2',
            border: '1px solid #fecaca',
            borderRadius: 6,
            fontSize: 14
          }}>
            {error}
          </div>
        )}
        
        <div style={{ 
          textAlign: 'center', 
          marginTop: 24,
          paddingTop: 24,
          borderTop: '1px solid #e5e7eb'
        }}>
          <button
            onClick={() => setIsSignUp(!isSignUp)}
            style={{
              background: 'none',
              border: 'none',
              color: '#3b82f6',
              cursor: 'pointer',
              fontSize: 14,
              textDecoration: 'underline'
            }}
          >
            {isSignUp ? 'Already have an account? Sign In' : 'Need an account? Sign Up'}
          </button>
        </div>
      </div>
    </div>
  );
}