import React, { useState } from 'react';

const Sidebar = ({ user, onLogout }) => {
  const [activeTab, setActiveTab] = useState('dashboard');

  const adminTabs = [
    { id: 'dashboard', label: 'Dashboard', icon: '📊' },
    { id: 'users', label: 'User Management', icon: '👥' },
    { id: 'pairs', label: 'Pairing', icon: '🤝' },
    { id: 'analytics', label: 'Analytics', icon: '📈' }
  ];

  const userTabs = [
    { id: 'goals', label: 'Goals', icon: '🎯' },
    { id: 'sessions', label: 'Sessions', icon: '📅' },
    { id: 'feedback', label: 'Feedback', icon: '⭐' },
    { id: 'materials', label: 'Materials', icon: '📚' }
  ];

  const tabs = user?.role === 'admin' ? adminTabs : userTabs;

  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <h3>Mentoring Matters</h3>
        <div className="user-info">
          <span className="user-role">{user?.role || 'user'}</span>
          <span className="user-org">{user?.organization || 'No Organization'}</span>
        </div>
      </div>

      <nav className="sidebar-nav">
        <ul>
          {tabs.map(tab => (
            <li 
              key={tab.id}
              className={activeTab === tab.id ? 'active' : ''}
              onClick={() => setActiveTab(tab.id)}
            >
              <span className="tab-icon">{tab.icon}</span>
              <span className="tab-label">{tab.label}</span>
            </li>
          ))}
        </ul>
      </nav>

      <div className="sidebar-footer">
        <button onClick={onLogout} className="logout-btn">
          🚪 Logout
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;
