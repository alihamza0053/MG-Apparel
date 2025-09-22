import React, { useState } from 'react';
import axios from 'axios';

const MaterialsTab = ({ data, onRefresh }) => {
  const [newMaterial, setNewMaterial] = useState({ 
    pair_id: '', 
    title: '', 
    description: '', 
    url: '', 
    type: 'link' 
  });
  const [showForm, setShowForm] = useState(false);

  const materials = data.materials || [];
  const pairs = data.pairs || [];

  const handleCreateMaterial = async (e) => {
    e.preventDefault();
    try {
      await axios.post('/api/materials', newMaterial);
      setNewMaterial({ 
        pair_id: '', 
        title: '', 
        description: '', 
        url: '', 
        type: 'link' 
      });
      setShowForm(false);
      onRefresh();
    } catch (err) {
      alert('Error sharing material: ' + err.response?.data?.message);
    }
  };

  return (
    <div className="materials-tab">
      <div className="tab-header">
        <h2>Materials</h2>
        <button onClick={() => setShowForm(!showForm)} className="add-btn">
          {showForm ? 'Cancel' : 'Share Material'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleCreateMaterial} className="material-form">
          <select
            value={newMaterial.pair_id}
            onChange={(e) => setNewMaterial({ ...newMaterial, pair_id: e.target.value })}
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
            placeholder="Material Title"
            value={newMaterial.title}
            onChange={(e) => setNewMaterial({ ...newMaterial, title: e.target.value })}
            required
          />
          <textarea
            placeholder="Description"
            value={newMaterial.description}
            onChange={(e) => setNewMaterial({ ...newMaterial, description: e.target.value })}
          />
          <select
            value={newMaterial.type}
            onChange={(e) => setNewMaterial({ ...newMaterial, type: e.target.value })}
          >
            <option value="link">Link/URL</option>
            <option value="document">Document</option>
            <option value="video">Video</option>
            <option value="other">Other</option>
          </select>
          <input
            type="url"
            placeholder="URL (if applicable)"
            value={newMaterial.url}
            onChange={(e) => setNewMaterial({ ...newMaterial, url: e.target.value })}
          />
          <button type="submit">Share Material</button>
        </form>
      )}

      <div className="materials-list">
        {materials.map(material => (
          <div key={material.id} className="material-item">
            <div className="material-header">
              <h3>{material.title}</h3>
              <span className="material-type">{material.type}</span>
              <span className="material-date">
                {new Date(material.created_at).toLocaleDateString()}
              </span>
            </div>
            <div className="material-content">
              <p><strong>Shared by:</strong> {material.mentor?.name}</p>
              {material.pairs && (
                <p><strong>For pair:</strong> {material.pairs.mentor?.name} - {material.pairs.mentee?.name}</p>
              )}
              
              {material.description && (
                <div className="material-description">
                  <strong>Description:</strong>
                  <p>{material.description}</p>
                </div>
              )}
              
              {material.url && (
                <div className="material-link">
                  <strong>URL:</strong>
                  <a href={material.url} target="_blank" rel="noopener noreferrer">
                    {material.url}
                  </a>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

      {materials.length === 0 && (
        <div className="empty-state">
          <p>No materials shared yet. Mentors can share helpful resources here!</p>
        </div>
      )}
    </div>
  );
};

export default MaterialsTab;
