import React, { useState, useMemo, useCallback } from 'react';
import { useAuth } from './AuthContext';
import SessionBasedGoals from './components/SessionBasedGoals';
import SessionBasedFeedback from './components/SessionBasedFeedback';
import { Analytics } from './components/Analytics';
import { AdminPairs } from './components/AdminPairs';
import { UserManagement } from './components/UserManagement';
import { 
  Users, 
  Target, 
  MessageSquare, 
  BarChart3, 
  Settings, 
  LogOut,
  Menu,
  X
} from 'lucide-react';

interface DashboardProps {
  children?: React.ReactNode;
}

function DashboardComponent({ children }: DashboardProps) {
  const { user, signOut } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [activeTab, setActiveTab] = useState(user?.role === 'admin' ? 'analytics' : 'goals');
  const [signingOut, setSigningOut] = useState(false);

  const navItems = useMemo(() => {
    const baseItems = [
      { id: 'goals', label: 'Session Goals', icon: Target },
      { id: 'feedback', label: 'Session Feedback', icon: MessageSquare },
    ];

    if (user?.role === 'admin') {
      return [
        { id: 'analytics', label: 'Analytics', icon: BarChart3 },
        { id: 'users', label: 'Manage Users', icon: Users },
        { id: 'pairs', label: 'Mentor Pairs', icon: Users },
        ...baseItems,
      ];
    }

    return baseItems;
  }, [user?.role]);

  const handleSignOut = useCallback(async () => {
    if (signingOut) return;
    
    try {
      setSigningOut(true);
      console.log('Signing out...');
      await signOut();
      console.log('Signed out successfully');
    } catch (error) {
      console.error('Error signing out:', error);
      alert('Error signing out. Please try again.');
    } finally {
      setSigningOut(false);
    }
  }, [signingOut, signOut]);

  const renderContent = useMemo(() => {
    if (children) return children;
    
    switch (activeTab) {
      case 'analytics':
        return <Analytics />;
      case 'pairs':
        return <AdminPairs />;
      case 'goals':
        return <SessionBasedGoals />;
      case 'feedback':
        return <SessionBasedFeedback />;
      case 'users':
        return <UserManagement />;
      default:
        return (
          <div style={{
            textAlign: 'center',
            padding: 40,
            background: 'white',
            borderRadius: 12,
            boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)'
          }}>
            <h2 style={{
              fontSize: 24,
              fontWeight: 'bold',
              color: '#1e40af',
              marginBottom: 16
            }}>
              Welcome to Mentoring Matters!
            </h2>
            <p style={{
              color: '#64748b',
              fontSize: 16,
              marginBottom: 24
            }}>
              Hello {user?.full_name || user?.email}! You're logged in as a {user?.role}.
            </p>
            <p style={{
              color: '#64748b',
              fontSize: 14
            }}>
              Use the sidebar to navigate through the different features available for your role.
            </p>
          </div>
        );
    }
  }, [children, activeTab, user?.full_name, user?.email, user?.role]);

  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: '#f8fafc' }}>
      {/* Mobile menu overlay */}
      {sidebarOpen && (
        <div 
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(0, 0, 0, 0.5)',
            zIndex: 40,
            display: window.innerWidth >= 768 ? 'none' : 'block'
          }}
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <div style={{
        position: window.innerWidth >= 768 ? 'static' : 'fixed',
        left: sidebarOpen || window.innerWidth >= 768 ? 0 : '-100%',
        top: 0,
        height: '100vh',
        width: 280,
        background: 'white',
        borderRight: '1px solid #e2e8f0',
        zIndex: 50,
        transition: 'left 0.3s ease-in-out',
        display: 'flex',
        flexDirection: 'column'
      }}>
        {/* Header */}
        <div style={{
          padding: 24,
          borderBottom: '1px solid #e2e8f0',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between'
        }}>
          <h1 style={{
            fontSize: 20,
            fontWeight: 'bold',
            color: '#1e40af',
            margin: 0
          }}>
            Mentoring Matters
          </h1>
          <button
            onClick={() => setSidebarOpen(false)}
            style={{
              display: window.innerWidth >= 768 ? 'none' : 'block',
              background: 'none',
              border: 'none',
              cursor: 'pointer',
              padding: 4
            }}
          >
            <X size={20} color="#64748b" />
          </button>
        </div>

        {/* User info */}
        <div style={{
          padding: 16,
          borderBottom: '1px solid #e2e8f0'
        }}>
          <div style={{
            fontSize: 14,
            fontWeight: 500,
            color: '#374151',
            marginBottom: 4
          }}>
            {user?.full_name || user?.email}
          </div>
          <div style={{
            fontSize: 12,
            background: user?.role === 'admin' ? '#fef3c7' : user?.role === 'mentor' ? '#dbeafe' : '#f3e8ff',
            color: user?.role === 'admin' ? '#92400e' : user?.role === 'mentor' ? '#1e40af' : '#7c3aed',
            padding: '2px 8px',
            borderRadius: 12,
            display: 'inline-block',
            textTransform: 'capitalize'
          }}>
            {user?.role}
          </div>
        </div>

        {/* Navigation */}
        <nav style={{ flex: 1, padding: 16 }}>
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => {
                  setActiveTab(item.id);
                  setSidebarOpen(false);
                }}
                style={{
                  width: '100%',
                  display: 'flex',
                  alignItems: 'center',
                  padding: 12,
                  marginBottom: 4,
                  background: isActive ? '#dbeafe' : 'none',
                  border: 'none',
                  borderRadius: 8,
                  cursor: 'pointer',
                  transition: 'background-color 0.2s',
                  fontSize: 14,
                  fontWeight: 500,
                  color: isActive ? '#1e40af' : '#374151'
                }}
                onMouseEnter={e => {
                  if (!isActive) e.currentTarget.style.backgroundColor = '#f1f5f9';
                }}
                onMouseLeave={e => {
                  if (!isActive) e.currentTarget.style.backgroundColor = 'transparent';
                }}
              >
                <Icon size={18} style={{ marginRight: 12 }} />
                {item.label}
              </button>
            );
          })}
        </nav>

        {/* Sign out */}
        <div style={{ padding: 16, borderTop: '1px solid #e2e8f0' }}>
          <button
            onClick={handleSignOut}
            disabled={signingOut}
            style={{
              width: '100%',
              display: 'flex',
              alignItems: 'center',
              padding: 12,
              background: 'none',
              border: 'none',
              borderRadius: 8,
              cursor: signingOut ? 'not-allowed' : 'pointer',
              fontSize: 14,
              fontWeight: 500,
              color: signingOut ? '#9ca3af' : '#ef4444',
              opacity: signingOut ? 0.6 : 1,
              transition: 'background-color 0.2s'
            }}
            onMouseEnter={e => !signingOut && (e.currentTarget.style.backgroundColor = '#fef2f2')}
            onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}
          >
            <LogOut size={18} style={{ marginRight: 12 }} />
            {signingOut ? 'Signing Out...' : 'Sign Out'}
          </button>
        </div>
      </div>

      {/* Main content */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
        {/* Mobile header */}
        <div style={{
          display: window.innerWidth >= 768 ? 'none' : 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: 16,
          background: 'white',
          borderBottom: '1px solid #e2e8f0'
        }}>
          <button
            onClick={() => setSidebarOpen(true)}
            style={{
              background: 'none',
              border: 'none',
              cursor: 'pointer',
              padding: 4
            }}
          >
            <Menu size={24} color="#374151" />
          </button>
          <h1 style={{
            fontSize: 18,
            fontWeight: 'bold',
            color: '#1e40af',
            margin: 0
          }}>
            Mentoring Matters
          </h1>
          <div style={{ width: 32 }} />
        </div>

        {/* Content area */}
        <div style={{
          flex: 1,
          padding: window.innerWidth >= 768 ? 32 : 16,
          maxWidth: '100%',
          overflow: 'auto'
        }}>
          {renderContent}
        </div>
      </div>
    </div>
  );
}

export const Dashboard = React.memo(DashboardComponent);