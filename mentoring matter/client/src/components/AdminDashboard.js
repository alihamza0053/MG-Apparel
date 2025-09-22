import React, { useState } from 'react';
import axios from 'axios';
import { Bar, Pie } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
} from 'chart.js';

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement
);

const AdminDashboard = ({ data, onRefresh }) => {
  const [activeSection, setActiveSection] = useState('overview');
  const [newUser, setNewUser] = useState({ name: '', email: '', password: '', role: 'mentee' });
  const [newPair, setNewPair] = useState({ mentor_id: '', mentee_id: '', start_date: '' });
  const [availableUsers, setAvailableUsers] = useState({ mentors: [], mentees: [] });

  React.useEffect(() => {
    loadAvailableUsers();
  }, []);

  const loadAvailableUsers = async () => {
    try {
      console.log('Loading available users...');
      const response = await axios.get('/api/users/available');
      console.log('Available users response:', response.data);
      setAvailableUsers(response.data);
    } catch (err) {
      console.error('Error loading available users:', err);
      // Fallback: use users from data prop
      if (data.users) {
        const mentors = data.users.filter(u => u.role === 'mentor');
        const mentees = data.users.filter(u => u.role === 'mentee');
        setAvailableUsers({ mentors, mentees });
        console.log('Using fallback users:', { mentors, mentees });
      }
    }
  };

  const handleCreateUser = async (e) => {
    e.preventDefault();
    try {
      await axios.post('/api/users', newUser);
      setNewUser({ name: '', email: '', password: '', role: 'mentee' });
      onRefresh();
      loadAvailableUsers(); // Refresh available users
      alert('User created successfully!');
    } catch (err) {
      alert('Error creating user: ' + err.response?.data?.message);
    }
  };

  const handleCreatePair = async (e) => {
    e.preventDefault();
    try {
      const pairData = {
        ...newPair,
        start_date: newPair.start_date || new Date().toISOString().split('T')[0]
      };
      await axios.post('/api/pairs', pairData);
      setNewPair({ mentor_id: '', mentee_id: '', start_date: '' });
      onRefresh();
      loadAvailableUsers(); // Refresh available users
      alert('Pair created successfully!');
    } catch (err) {
      alert('Error creating pair: ' + err.response?.data?.message);
    }
  };

  const handleExportCSV = async () => {
    try {
      const response = await axios.get('/api/analytics/export', {
        responseType: 'blob'
      });
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', 'mentoring-pairs.csv');
      document.body.appendChild(link);
      link.click();
      link.remove();
    } catch (err) {
      alert('Error exporting CSV');
    }
  };

  const analytics = data.analytics || {};
  const users = data.users || [];
  const pairs = data.pairs || [];

  const goalChartData = {
    labels: ['Not Started', 'In Progress', 'Completed'],
    datasets: [{
      data: [
        analytics.goalStats?.['Not Started'] || 0,
        analytics.goalStats?.['In Progress'] || 0,
        analytics.goalStats?.['Completed'] || 0
      ],
      backgroundColor: ['#ff9999', '#ffcc99', '#99ff99']
    }]
  };

  const userChartData = {
    labels: ['Admins', 'Mentors', 'Mentees'],
    datasets: [{
      data: [
        analytics.userStats?.admin || 0,
        analytics.userStats?.mentor || 0,
        analytics.userStats?.mentee || 0
      ],
      backgroundColor: ['#1976d2', '#2196f3', '#bbdefb']
    }]
  };

  return (
    <div className="admin-dashboard">
      <div className="admin-nav">
        <button 
          className={activeSection === 'overview' ? 'active' : ''}
          onClick={() => setActiveSection('overview')}
        >
          Overview
        </button>
        <button 
          className={activeSection === 'users' ? 'active' : ''}
          onClick={() => setActiveSection('users')}
        >
          User Management
        </button>
        <button 
          className={activeSection === 'pairs' ? 'active' : ''}
          onClick={() => setActiveSection('pairs')}
        >
          Pairing
        </button>
        <button 
          className={activeSection === 'analytics' ? 'active' : ''}
          onClick={() => setActiveSection('analytics')}
        >
          Analytics
        </button>
      </div>

      {activeSection === 'overview' && (
        <div className="overview-section">
          <div className="stats-grid">
            <div className="stat-card">
              <h3>Active Pairs</h3>
              <div className="stat-number">{analytics.activePairs || 0}</div>
            </div>
            <div className="stat-card">
              <h3>Total Sessions</h3>
              <div className="stat-number">{analytics.totalSessions || 0}</div>
            </div>
            <div className="stat-card">
              <h3>Average Rating</h3>
              <div className="stat-number">{analytics.avgRating || 0}/5</div>
            </div>
            <div className="stat-card">
              <h3>Total Users</h3>
              <div className="stat-number">{users.length}</div>
            </div>
          </div>
        </div>
      )}

      {activeSection === 'users' && (
        <div className="users-section">
          <h3>Create New User</h3>
          <form onSubmit={handleCreateUser} className="create-form">
            <input
              type="text"
              placeholder="Name"
              value={newUser.name}
              onChange={(e) => setNewUser({ ...newUser, name: e.target.value })}
              required
            />
            <input
              type="email"
              placeholder="Email"
              value={newUser.email}
              onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
              required
            />
            <input
              type="password"
              placeholder="Password"
              value={newUser.password}
              onChange={(e) => setNewUser({ ...newUser, password: e.target.value })}
              required
            />
            <select
              value={newUser.role}
              onChange={(e) => setNewUser({ ...newUser, role: e.target.value })}
            >
              <option value="mentee">Mentee</option>
              <option value="mentor">Mentor</option>
              <option value="admin">Admin</option>
            </select>
            <button type="submit">Create User</button>
          </form>

          <h3>Existing Users</h3>
          <div className="users-list">
            {users.map(user => (
              <div key={user.id} className="user-item">
                <span>{user.name} ({user.email})</span>
                <span className="user-role">{user.role}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {activeSection === 'pairs' && (
        <div className="pairs-section">
          <h3>Create New Pair</h3>
          
          {/* Debug Section */}
          <div style={{background: '#f0f0f0', padding: '10px', margin: '10px 0', fontSize: '12px'}}>
            <strong>Debug Info:</strong><br/>
            Available Mentors: {availableUsers.mentors?.length || 0}<br/>
            Available Mentees: {availableUsers.mentees?.length || 0}<br/>
            Total Users: {users.length}<br/>
            Users data: {JSON.stringify(users.slice(0,2))}
          </div>
          
          <form onSubmit={handleCreatePair} className="create-form">
            <select
              value={newPair.mentor_id}
              onChange={(e) => setNewPair({ ...newPair, mentor_id: e.target.value })}
              required
            >
              <option value="">Select Mentor</option>
              {availableUsers.mentors.map(mentor => (
                <option key={mentor.id} value={mentor.id}>{mentor.name} ({mentor.email})</option>
              ))}
            </select>
            <select
              value={newPair.mentee_id}
              onChange={(e) => setNewPair({ ...newPair, mentee_id: e.target.value })}
              required
            >
              <option value="">Select Mentee</option>
              {availableUsers.mentees.map(mentee => (
                <option key={mentee.id} value={mentee.id}>{mentee.name} ({mentee.email})</option>
              ))}
            </select>
            <input
              type="date"
              value={newPair.start_date}
              onChange={(e) => setNewPair({ ...newPair, start_date: e.target.value })}
              placeholder="Start Date"
            />
            <button type="submit">Create Pair</button>
          </form>

          <h3>Existing Pairs</h3>
          <div className="pairs-list">
            {pairs.map(pair => (
              <div key={pair.id} className="pair-item">
                <div>
                  <strong>Mentor:</strong> {pair.mentor?.name} ({pair.mentor?.email})
                </div>
                <div>
                  <strong>Mentee:</strong> {pair.mentee?.name} ({pair.mentee?.email})
                </div>
                <div>
                  <strong>Status:</strong> {pair.status}
                </div>
                <div>
                  <strong>Start Date:</strong> {pair.start_date ? new Date(pair.start_date).toLocaleDateString() : 'Not set'}
                </div>
              </div>
            ))}
            {pairs.length === 0 && (
              <p>No pairs created yet. Create your first mentor-mentee pair above!</p>
            )}
          </div>
        </div>
      )}

      {activeSection === 'analytics' && (
        <div className="analytics-section">
          <div className="analytics-header">
            <h3>Analytics Dashboard</h3>
            <button onClick={handleExportCSV} className="export-btn">
              Export CSV
            </button>
          </div>

          <div className="charts-grid">
            <div className="chart-container">
              <h4>Goal Progress</h4>
              <Pie data={goalChartData} />
            </div>
            <div className="chart-container">
              <h4>Users by Role</h4>
              <Bar data={userChartData} />
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AdminDashboard;
