import React, { useState } from 'react';
import axios from 'axios';

const GoalsTab = ({ data, onRefresh }) => {
  const [newGoal, setNewGoal] = useState({ pair_id: '', title: '', description: '' });
  const [showForm, setShowForm] = useState(false);

  const goals = data.goals || [];
  const pairs = data.pairs || [];

  const handleCreateGoal = async (e) => {
    e.preventDefault();
    try {
      await axios.post('/api/goals', newGoal);
      setNewGoal({ pair_id: '', title: '', description: '' });
      setShowForm(false);
      onRefresh();
    } catch (err) {
      alert('Error creating goal: ' + err.response?.data?.message);
    }
  };

  const handleUpdateStatus = async (goalId, status) => {
    try {
      await axios.put(`/api/goals/${goalId}`, { status });
      onRefresh();
    } catch (err) {
      alert('Error updating goal: ' + err.response?.data?.message);
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'not_started': return '#ff9999';
      case 'in_progress': return '#ffcc99';
      case 'completed': return '#99ff99';
      default: return '#ddd';
    }
  };

  return (
    <div className="goals-tab">
      <div className="tab-header">
        <h2>Goals</h2>
        <button onClick={() => setShowForm(!showForm)} className="add-btn">
          {showForm ? 'Cancel' : 'Add Goal'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleCreateGoal} className="goal-form">
          <select
            value={newGoal.pair_id}
            onChange={(e) => setNewGoal({ ...newGoal, pair_id: e.target.value })}
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
            type="text"
            placeholder="Goal Title"
            value={newGoal.title}
            onChange={(e) => setNewGoal({ ...newGoal, title: e.target.value })}
            required
          />
          <textarea
            placeholder="Goal Description"
            value={newGoal.description}
            onChange={(e) => setNewGoal({ ...newGoal, description: e.target.value })}
          />
          <button type="submit">Create Goal</button>
        </form>
      )}

      <div className="goals-list">
        {goals.map(goal => (
          <div key={goal.id} className="goal-item">
            <div className="goal-content">
              <h3>{goal.title}</h3>
              <p>{goal.description}</p>
              <div className="goal-meta">
                <span>Created: {new Date(goal.created_at).toLocaleDateString()}</span>
                {goal.pairs && (
                  <span>Pair: {goal.pairs.mentor?.name} - {goal.pairs.mentee?.name}</span>
                )}
              </div>
            </div>
            <div className="goal-status">
              <div 
                className="status-indicator"
                style={{ backgroundColor: getStatusColor(goal.status) }}
              >
                {goal.status.replace('_', ' ')}
              </div>
              <select
                value={goal.status}
                onChange={(e) => handleUpdateStatus(goal.id, e.target.value)}
                className="status-select"
              >
                <option value="not_started">Not Started</option>
                <option value="in_progress">In Progress</option>
                <option value="completed">Completed</option>
              </select>
            </div>
          </div>
        ))}
      </div>

      {goals.length === 0 && (
        <div className="empty-state">
          <p>No goals yet. Create your first goal to get started!</p>
        </div>
      )}
    </div>
  );
};

export default GoalsTab;
