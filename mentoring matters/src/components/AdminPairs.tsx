import React, { useState, useEffect } from 'react';
import { supabase } from '../supabaseClient';
import { useAuth } from '../AuthContext';
import { User, MentoringPair } from '../types';
import { Users, Plus, UserPlus, Link } from 'lucide-react';

export function AdminPairs() {
  const { user } = useAuth();
  const [pairs, setPairs] = useState<MentoringPair[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [newPair, setNewPair] = useState({
    mentor_id: '',
    mentee_id: ''
  });

  useEffect(() => {
    if (user?.role === 'admin') {
      fetchData();
    }
  }, [user]);

  const fetchData = async () => {
    try {
      // Fetch all users (remove organization filter for now)
      const { data: usersData, error: usersError } = await supabase
        .from('profiles')
        .select('*');

      if (usersError) throw usersError;
      setUsers(usersData || []);

      // Fetch all mentoring pairs (remove organization filter for now)
      const { data: pairsData, error: pairsError } = await supabase
        .from('mentoring_pairs')
        .select(`
          *,
          mentor:profiles!mentor_id(id, full_name, email, role),
          mentee:profiles!mentee_id(id, full_name, email, role)
        `);

      if (pairsError) throw pairsError;
      setPairs(pairsData || []);

    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreatePair = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const { error } = await supabase
        .from('mentoring_pairs')
        .insert([{
          ...newPair,
          status: 'active'
        }]);

      if (error) throw error;
      
      setNewPair({ mentor_id: '', mentee_id: '' });
      setShowCreateForm(false);
      fetchData();
    } catch (error) {
      console.error('Error creating pair:', error);
    }
  };

  const updatePairStatus = async (pairId: string, status: 'active' | 'inactive' | 'completed') => {
    try {
      const { error } = await supabase
        .from('mentoring_pairs')
        .update({ 
          status,
          ended_at: status !== 'active' ? new Date().toISOString() : null
        })
        .eq('id', pairId);

      if (error) throw error;
      fetchData();
    } catch (error) {
      console.error('Error updating pair status:', error);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return '#22c55e';
      case 'completed':
        return '#3b82f6';
      case 'inactive':
        return '#6b7280';
      default:
        return '#6b7280';
    }
  };

  const mentors = users.filter(u => u.role === 'mentor');
  const mentees = users.filter(u => u.role === 'mentee');

  if (user?.role !== 'admin') {
    return (
      <div style={{
        background: 'white',
        padding: 40,
        borderRadius: 12,
        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
        textAlign: 'center'
      }}>
        <h3 style={{
          fontSize: 18,
          fontWeight: 600,
          color: '#374151',
          margin: '0 0 8px 0'
        }}>
          Access Denied
        </h3>
        <p style={{
          color: '#64748b',
          margin: 0,
          fontSize: 14
        }}>
          Only administrators can manage mentoring pairs.
        </p>
      </div>
    );
  }

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: 40 }}>
        <div style={{
          width: 40,
          height: 40,
          border: '4px solid #e2e8f0',
          borderTop: '4px solid #3b82f6',
          borderRadius: '50%',
          animation: 'spin 1s linear infinite',
          margin: '0 auto 16px'
        }} />
        <p style={{ color: '#64748b' }}>Loading mentoring pairs...</p>
      </div>
    );
  }

  return (
    <div>
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 24
      }}>
        <div>
          <h1 style={{
            fontSize: 24,
            fontWeight: 'bold',
            color: '#1e40af',
            margin: 0,
            marginBottom: 4
          }}>
            Mentoring Pairs
          </h1>
          <p style={{
            color: '#64748b',
            margin: 0,
            fontSize: 14
          }}>
            Manage mentor-mentee relationships
          </p>
        </div>
        
        <button
          onClick={() => setShowCreateForm(true)}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            padding: '12px 16px',
            background: '#3b82f6',
            color: 'white',
            border: 'none',
            borderRadius: 8,
            cursor: 'pointer',
            fontSize: 14,
            fontWeight: 500
          }}
        >
          <Link size={16} />
          Create Pair
        </button>
      </div>

      {showCreateForm && (
        <div style={{
          background: 'white',
          padding: 24,
          borderRadius: 12,
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          marginBottom: 24
        }}>
          <h3 style={{
            fontSize: 18,
            fontWeight: 600,
            color: '#374151',
            margin: '0 0 16px 0'
          }}>
            Create New Mentoring Pair
          </h3>
          
          <form onSubmit={handleCreatePair}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 24 }}>
              <div>
                <label style={{
                  display: 'block',
                  marginBottom: 4,
                  fontSize: 14,
                  fontWeight: 500,
                  color: '#374151'
                }}>
                  Mentor
                </label>
                <select
                  value={newPair.mentor_id}
                  onChange={e => setNewPair({...newPair, mentor_id: e.target.value})}
                  required
                  style={{
                    width: '100%',
                    padding: 12,
                    border: '1px solid #d1d5db',
                    borderRadius: 6,
                    fontSize: 14
                  }}
                >
                  <option value="">Select a mentor</option>
                  {mentors.map(mentor => (
                    <option key={mentor.id} value={mentor.id}>
                      {mentor.full_name || mentor.email}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label style={{
                  display: 'block',
                  marginBottom: 4,
                  fontSize: 14,
                  fontWeight: 500,
                  color: '#374151'
                }}>
                  Mentee
                </label>
                <select
                  value={newPair.mentee_id}
                  onChange={e => setNewPair({...newPair, mentee_id: e.target.value})}
                  required
                  style={{
                    width: '100%',
                    padding: 12,
                    border: '1px solid #d1d5db',
                    borderRadius: 6,
                    fontSize: 14
                  }}
                >
                  <option value="">Select a mentee</option>
                  {mentees.map(mentee => (
                    <option key={mentee.id} value={mentee.id}>
                      {mentee.full_name || mentee.email}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div style={{ display: 'flex', gap: 12 }}>
              <button
                type="submit"
                style={{
                  padding: '12px 16px',
                  background: '#3b82f6',
                  color: 'white',
                  border: 'none',
                  borderRadius: 6,
                  cursor: 'pointer',
                  fontSize: 14,
                  fontWeight: 500
                }}
              >
                Create Pair
              </button>
              <button
                type="button"
                onClick={() => setShowCreateForm(false)}
                style={{
                  padding: '12px 16px',
                  background: '#f3f4f6',
                  color: '#374151',
                  border: 'none',
                  borderRadius: 6,
                  cursor: 'pointer',
                  fontSize: 14,
                  fontWeight: 500
                }}
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Stats Cards */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: 16,
        marginBottom: 24
      }}>
        <div style={{
          background: 'white',
          padding: 20,
          borderRadius: 12,
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          borderLeft: '4px solid #22c55e'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8 }}>
            <Users size={20} color="#22c55e" />
            <span style={{ fontSize: 14, fontWeight: 500, color: '#64748b' }}>Total Pairs</span>
          </div>
          <div style={{ fontSize: 24, fontWeight: 'bold', color: '#1f2937' }}>
            {pairs.length}
          </div>
        </div>

        <div style={{
          background: 'white',
          padding: 20,
          borderRadius: 12,
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          borderLeft: '4px solid #3b82f6'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8 }}>
            <Users size={20} color="#3b82f6" />
            <span style={{ fontSize: 14, fontWeight: 500, color: '#64748b' }}>Active Pairs</span>
          </div>
          <div style={{ fontSize: 24, fontWeight: 'bold', color: '#1f2937' }}>
            {pairs.filter(p => p.status === 'active').length}
          </div>
        </div>

        <div style={{
          background: 'white',
          padding: 20,
          borderRadius: 12,
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          borderLeft: '4px solid #f59e0b'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8 }}>
            <UserPlus size={20} color="#f59e0b" />
            <span style={{ fontSize: 14, fontWeight: 500, color: '#64748b' }}>Available Mentors</span>
          </div>
          <div style={{ fontSize: 24, fontWeight: 'bold', color: '#1f2937' }}>
            {mentors.length}
          </div>
        </div>

        <div style={{
          background: 'white',
          padding: 20,
          borderRadius: 12,
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          borderLeft: '4px solid #8b5cf6'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8 }}>
            <UserPlus size={20} color="#8b5cf6" />
            <span style={{ fontSize: 14, fontWeight: 500, color: '#64748b' }}>Available Mentees</span>
          </div>
          <div style={{ fontSize: 24, fontWeight: 'bold', color: '#1f2937' }}>
            {mentees.length}
          </div>
        </div>
      </div>

      {/* Pairs List */}
      {pairs.length === 0 ? (
        <div style={{
          background: 'white',
          padding: 40,
          borderRadius: 12,
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          textAlign: 'center'
        }}>
          <Users size={48} color="#9ca3af" style={{ margin: '0 auto 16px' }} />
          <h3 style={{
            fontSize: 18,
            fontWeight: 600,
            color: '#374151',
            margin: '0 0 8px 0'
          }}>
            No mentoring pairs yet
          </h3>
          <p style={{
            color: '#64748b',
            margin: 0,
            fontSize: 14
          }}>
            Create your first mentoring pair to get started.
          </p>
        </div>
      ) : (
        <div style={{
          background: 'white',
          borderRadius: 12,
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          overflow: 'hidden'
        }}>
          <div style={{
            display: 'grid',
            gridTemplateColumns: '2fr 2fr 1fr 1fr 1fr',
            gap: 16,
            padding: 16,
            background: '#f8fafc',
            fontSize: 14,
            fontWeight: 600,
            color: '#374151',
            borderBottom: '1px solid #e2e8f0'
          }}>
            <div>Mentor</div>
            <div>Mentee</div>
            <div>Status</div>
            <div>Created</div>
            <div>Actions</div>
          </div>

          {pairs.map(pair => (
            <div
              key={pair.id}
              style={{
                display: 'grid',
                gridTemplateColumns: '2fr 2fr 1fr 1fr 1fr',
                gap: 16,
                padding: 16,
                borderBottom: '1px solid #e2e8f0',
                alignItems: 'center'
              }}
            >
              <div>
                <div style={{ fontWeight: 500, color: '#374151' }}>
                  {pair.mentor?.full_name || pair.mentor?.email}
                </div>
                <div style={{ fontSize: 12, color: '#64748b' }}>
                  {pair.mentor?.email}
                </div>
              </div>

              <div>
                <div style={{ fontWeight: 500, color: '#374151' }}>
                  {pair.mentee?.full_name || pair.mentee?.email}
                </div>
                <div style={{ fontSize: 12, color: '#64748b' }}>
                  {pair.mentee?.email}
                </div>
              </div>

              <div>
                <span style={{
                  padding: '4px 8px',
                  borderRadius: 12,
                  fontSize: 12,
                  fontWeight: 500,
                  background: pair.status === 'active' ? '#dcfce7' : pair.status === 'completed' ? '#dbeafe' : '#f3f4f6',
                  color: pair.status === 'active' ? '#166534' : pair.status === 'completed' ? '#1e40af' : '#374151'
                }}>
                  {pair.status.charAt(0).toUpperCase() + pair.status.slice(1)}
                </span>
              </div>

              <div style={{ fontSize: 12, color: '#64748b' }}>
                {new Date(pair.created_at).toLocaleDateString()}
              </div>

              <div style={{ display: 'flex', gap: 8 }}>
                {pair.status === 'active' && (
                  <>
                    <button
                      onClick={() => updatePairStatus(pair.id, 'completed')}
                      style={{
                        padding: '4px 8px',
                        background: '#dbeafe',
                        color: '#1e40af',
                        border: 'none',
                        borderRadius: 4,
                        cursor: 'pointer',
                        fontSize: 11,
                        fontWeight: 500
                      }}
                    >
                      Complete
                    </button>
                    <button
                      onClick={() => updatePairStatus(pair.id, 'inactive')}
                      style={{
                        padding: '4px 8px',
                        background: '#f3f4f6',
                        color: '#374151',
                        border: 'none',
                        borderRadius: 4,
                        cursor: 'pointer',
                        fontSize: 11,
                        fontWeight: 500
                      }}
                    >
                      Deactivate
                    </button>
                  </>
                )}
                {pair.status !== 'active' && (
                  <button
                    onClick={() => updatePairStatus(pair.id, 'active')}
                    style={{
                      padding: '4px 8px',
                      background: '#dcfce7',
                      color: '#166534',
                      border: 'none',
                      borderRadius: 4,
                      cursor: 'pointer',
                      fontSize: 11,
                      fontWeight: 500
                    }}
                  >
                    Reactivate
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}