import React, { useState, useEffect } from 'react';
import axios from 'axios';
import AdminDashboard from './AdminDashboard';
import GoalsTab from './GoalsTab';
import SessionsTab from './SessionsTab';
import FeedbackTab from './FeedbackTab';
import MaterialsTab from './MaterialsTab';

const Dashboard = ({ user }) => {
  const [activeTab, setActiveTab] = useState(user?.role === 'admin' ? 'dashboard' : 'goals');
  const [data, setData] = useState({});
  const [loading, setLoading] = useState(false);

  const loadData = async () => {
    setLoading(true);
    try {
      if (user?.role === 'admin') {
        const [usersRes, pairsRes, analyticsRes] = await Promise.all([
          axios.get('/api/users'),
          axios.get('/api/pairs'),
          axios.get('/api/analytics')
        ]);
        setData({
          users: usersRes.data,
          pairs: pairsRes.data,
          analytics: analyticsRes.data
        });
      } else {
        const [pairsRes, goalsRes, sessionsRes, feedbackRes, materialsRes] = await Promise.all([
          axios.get('/api/pairs'),
          axios.get('/api/goals'),
          axios.get('/api/sessions'),
          axios.get('/api/feedback'),
          axios.get('/api/materials')
        ]);
        setData({
          pairs: pairsRes.data,
          goals: goalsRes.data,
          sessions: sessionsRes.data,
          feedback: feedbackRes.data,
          materials: materialsRes.data
        });
      }
    } catch (err) {
      console.error('Error loading data:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [user]);

  const renderContent = () => {
    if (loading) {
      return <div className="loading">Loading...</div>;
    }

    // Debug section to show pairs data
    if (user?.role !== 'admin') {
      console.log('Dashboard pairs data:', data.pairs);
      console.log('User role:', user?.role);
      console.log('User ID:', user?.id);
    }

    switch (activeTab) {
      case 'dashboard':
        return (
          <div>
            <AdminDashboard data={data} onRefresh={loadData} />
            {user?.role !== 'admin' && (
              <div style={{marginTop: '20px', padding: '15px', background: '#f0f0f0', borderRadius: '8px'}}>
                <h3>Debug Info:</h3>
                <p><strong>User Role:</strong> {user?.role}</p>
                <p><strong>User ID:</strong> {user?.id}</p>
                <p><strong>Pairs Count:</strong> {data.pairs?.length || 0}</p>
                <p><strong>Pairs Data:</strong></p>
                <pre style={{fontSize: '12px', overflow: 'auto'}}>{JSON.stringify(data.pairs, null, 2)}</pre>
              </div>
            )}
          </div>
        );
      case 'goals':
        return <GoalsTab data={data} onRefresh={loadData} />;
      case 'sessions':
        return <SessionsTab data={data} onRefresh={loadData} />;
      case 'feedback':
        return <FeedbackTab data={data} onRefresh={loadData} />;
      case 'materials':
        return <MaterialsTab data={data} onRefresh={loadData} />;
      default:
        return <div>Select a tab from the sidebar</div>;
    }
  };

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <h1>Welcome, {user?.role ? user.role.charAt(0).toUpperCase() + user.role.slice(1) : 'User'}</h1>
      </header>
      
      {user?.role !== 'admin' && (
        <div className="tab-navigation">
          {['goals', 'sessions', 'feedback', 'materials'].map(tab => (
            <button
              key={tab}
              className={activeTab === tab ? 'active' : ''}
              onClick={() => setActiveTab(tab)}
            >
              {tab.charAt(0).toUpperCase() + tab.slice(1)}
            </button>
          ))}
        </div>
      )}

      <div className="dashboard-content">
        {renderContent()}
      </div>
    </div>
  );
};

export default Dashboard;
