import React, { useState } from 'react';
import axios from 'axios';

const FeedbackTab = ({ data, onRefresh }) => {
  const [newFeedback, setNewFeedback] = useState({ session_id: '', rating: 5, comments: '' });
  const [showForm, setShowForm] = useState(false);

  const feedback = data.feedback || [];
  const sessions = data.sessions || [];

  const handleCreateFeedback = async (e) => {
    e.preventDefault();
    try {
      await axios.post('/api/feedback', newFeedback);
      setNewFeedback({ session_id: '', rating: 5, comments: '' });
      setShowForm(false);
      onRefresh();
    } catch (err) {
      alert('Error submitting feedback: ' + err.response?.data?.message);
    }
  };

  const renderStars = (rating) => {
    return Array.from({ length: 5 }, (_, i) => (
      <span key={i} className={i < rating ? 'star filled' : 'star'}>
        ⭐
      </span>
    ));
  };

  return (
    <div className="feedback-tab">
      <div className="tab-header">
        <h2>Feedback</h2>
        <button onClick={() => setShowForm(!showForm)} className="add-btn">
          {showForm ? 'Cancel' : 'Give Feedback'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleCreateFeedback} className="feedback-form">
          <select
            value={newFeedback.session_id}
            onChange={(e) => setNewFeedback({ ...newFeedback, session_id: e.target.value })}
            required
          >
            <option value="">Select Session</option>
            {sessions.map(session => (
              <option key={session.id} value={session.id}>
                {new Date(session.date).toLocaleDateString()} - {session.pairs?.mentor?.name || 'Unknown'}
              </option>
            ))}
          </select>
          
          <div className="rating-input">
            <label>Rating (1-5 stars):</label>
            <select
              value={newFeedback.rating}
              onChange={(e) => setNewFeedback({ ...newFeedback, rating: parseInt(e.target.value) })}
            >
              {[1, 2, 3, 4, 5].map(num => (
                <option key={num} value={num}>{num} Star{num > 1 ? 's' : ''}</option>
              ))}
            </select>
          </div>

          <textarea
            placeholder="Your feedback and comments"
            value={newFeedback.comments}
            onChange={(e) => setNewFeedback({ ...newFeedback, comments: e.target.value })}
          />
          <button type="submit">Submit Feedback</button>
        </form>
      )}

      <div className="feedback-list">
        {feedback.map(fb => (
          <div key={fb.id} className="feedback-item">
            <div className="feedback-header">
              <div className="feedback-rating">
                {renderStars(fb.rating)}
                <span className="rating-number">({fb.rating}/5)</span>
              </div>
              <div className="feedback-meta">
                <span>By: {fb.users?.name} ({fb.users?.role})</span>
                <span>{new Date(fb.created_at).toLocaleDateString()}</span>
              </div>
            </div>
            <div className="feedback-content">
              <p><strong>Session:</strong> {new Date(fb.sessions?.date).toLocaleDateString()}</p>
              {fb.sessions?.pairs && (
                <p><strong>Pair:</strong> {fb.sessions.pairs.mentor?.name} - {fb.sessions.pairs.mentee?.name}</p>
              )}
              {fb.comments && (
                <div className="feedback-comment">
                  <strong>Comment:</strong>
                  <p>{fb.comments}</p>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

      {feedback.length === 0 && (
        <div className="empty-state">
          <p>No feedback submitted yet. Share your experience after sessions!</p>
        </div>
      )}
    </div>
  );
};

export default FeedbackTab;
