import React, { useState } from 'react';
import axios from 'axios';

const SessionsTab = ({ data, onRefresh }) => {
  const [newSession, setNewSession] = useState({ pair_id: '', date: '', duration: 60, notes: '' });
  const [showForm, setShowForm] = useState(false);

  const sessions = data.sessions || [];
  const pairs = data.pairs || [];

  const handleCreateSession = async (e) => {
    e.preventDefault();
    try {
      await axios.post('/api/sessions', newSession);
      setNewSession({ pair_id: '', date: '', duration: 60, notes: '' });
      setShowForm(false);
      onRefresh();
    } catch (err) {
      alert('Error creating session: ' + err.response?.data?.message);
    }
  };

  return (
    <div className="sessions-tab">
      <div className="tab-header">
        <h2>Sessions</h2>
        <button onClick={() => setShowForm(!showForm)} className="add-btn">
          {showForm ? 'Cancel' : 'Add Session'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleCreateSession} className="session-form">
          <select
            value={newSession.pair_id}
            onChange={(e) => setNewSession({ ...newSession, pair_id: e.target.value })}
            required
          >
            <option value="">Select Pair</option>
            {pairs.map(pair => (
              <option key={pair.id} value={pair.id}>
                {pair.mentor?.name} - {pair.mentee?.name}
              </option>
            ))}
          </select>
          <input
            type="datetime-local"
            value={newSession.date}
            onChange={(e) => setNewSession({ ...newSession, date: e.target.value })}
            required
          />
          <input
            type="number"
            placeholder="Duration (minutes)"
            value={newSession.duration}
            onChange={(e) => setNewSession({ ...newSession, duration: parseInt(e.target.value) })}
            min="15"
            max="480"
          />
          <textarea
            placeholder="Session Notes"
            value={newSession.notes}
            onChange={(e) => setNewSession({ ...newSession, notes: e.target.value })}
          />
          <button type="submit">Create Session</button>
        </form>
      )}

      <div className="sessions-list">
        {sessions.map(session => (
          <div key={session.id} className="session-item">
            <div className="session-header">
              <h3>Session on {new Date(session.date).toLocaleDateString()}</h3>
              <span className="session-time">
                {new Date(session.date).toLocaleTimeString()}
              </span>
              <span className="session-duration">
                {session.duration} minutes
              </span>
            </div>
            <div className="session-content">
              {session.pairs && (
                <p><strong>Pair:</strong> {session.pairs.mentor?.name} - {session.pairs.mentee?.name}</p>
              )}
              {session.notes && (
                <div className="session-notes">
                  <strong>Notes:</strong>
                  <p>{session.notes}</p>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

      {sessions.length === 0 && (
        <div className="empty-state">
          <p>No sessions recorded yet. Schedule your first session!</p>
        </div>
      )}
    </div>
  );
};

export default SessionsTab;
