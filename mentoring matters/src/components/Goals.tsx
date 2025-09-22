import React, { useState, useEffect } from 'react';
import { supabase } from '../supabaseClient';
import { useAuth } from '../AuthContext';
import { Goal, MentoringPair } from '../types';
import { Plus, Target, Clock, CheckCircle, Circle } from 'lucide-react';

function GoalsComponent() {
  const { user } = useAuth();
  const [goals, setGoals] = useState<Goal[]>([]);
  const [pairs, setPairs] = useState<MentoringPair[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddForm, setShowAddForm] = useState(false);
  const [newGoal, setNewGoal] = useState({
    title: '',
    description: '',
    target_date: '',
    pair_id: ''
  });

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      if (user?.role === 'admin') {
        // Admin can see all pairs and goals
        const { data: pairsData, error: pairsError } = await supabase
          .from('mentoring_pairs')
          .select(`
            *,
            mentor:profiles!mentor_id(id, full_name, email),
            mentee:profiles!mentee_id(id, full_name, email)
          `)
          .order('created_at', { ascending: false });

        if (pairsError) throw pairsError;
        setPairs(pairsData || []);

        // Fetch all goals for admin
        const { data: goalsData, error: goalsError } = await supabase
          .from('goals')
          .select(`
            *,
            pair:mentoring_pairs(
              id,
              mentor:profiles!mentor_id(full_name),
              mentee:profiles!mentee_id(full_name)
            )
          `)
          .order('created_at', { ascending: false });

        if (goalsError) throw goalsError;
        setGoals(goalsData || []);
      } else {
        // Fetch mentoring pairs for current user (mentor/mentee)
        const { data: pairsData, error: pairsError } = await supabase
          .from('mentoring_pairs')
          .select(`
            *,
            mentor:profiles!mentor_id(id, full_name, email),
            mentee:profiles!mentee_id(id, full_name, email)
          `)
          .or(`mentor_id.eq.${user?.id},mentee_id.eq.${user?.id}`);

        if (pairsError) throw pairsError;
        setPairs(pairsData || []);

        // Fetch goals for these pairs
        if (pairsData && pairsData.length > 0) {
          const pairIds = pairsData.map(p => p.id);
          const { data: goalsData, error: goalsError } = await supabase
            .from('goals')
            .select('*')
            .in('pair_id', pairIds)
            .order('created_at', { ascending: false });

          if (goalsError) throw goalsError;
          setGoals(goalsData || []);
        }
      }
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAddGoal = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const { error } = await supabase
        .from('goals')
        .insert([{
          ...newGoal,
          created_by: user?.id,
          target_date: newGoal.target_date || null
        }]);

      if (error) throw error;
      
      setNewGoal({ title: '', description: '', target_date: '', pair_id: '' });
      setShowAddForm(false);
      fetchData();
    } catch (error) {
      console.error('Error adding goal:', error);
    }
  };

  const updateGoalStatus = async (goalId: string, status: 'not_started' | 'in_progress' | 'completed') => {
    try {
      const { error } = await supabase
        .from('goals')
        .update({ status, updated_at: new Date().toISOString() })
        .eq('id', goalId);

      if (error) throw error;
      fetchData();
    } catch (error) {
      console.error('Error updating goal status:', error);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <CheckCircle size={20} color="#22c55e" />;
      case 'in_progress':
        return <Clock size={20} color="#f59e0b" />;
      default:
        return <Circle size={20} color="#6b7280" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return '#dcfce7';
      case 'in_progress':
        return '#fef3c7';
      default:
        return '#f3f4f6';
    }
  };

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
        <p style={{ color: '#64748b' }}>Loading goals...</p>
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
            Goals
          </h1>
          <p style={{
            color: '#64748b',
            margin: 0,
            fontSize: 14
          }}>
            Track and manage your mentoring goals
          </p>
        </div>
        
        <button
          onClick={() => setShowAddForm(true)}
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
          <Plus size={16} />
          Add Goal
        </button>
      </div>

      {showAddForm && (
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
            Add New Goal
          </h3>
          
          <form onSubmit={handleAddGoal}>
            <div style={{ marginBottom: 16 }}>
              <label style={{
                display: 'block',
                marginBottom: 4,
                fontSize: 14,
                fontWeight: 500,
                color: '#374151'
              }}>
                Mentoring Pair
              </label>
              <select
                value={newGoal.pair_id}
                onChange={e => setNewGoal({...newGoal, pair_id: e.target.value})}
                required
                style={{
                  width: '100%',
                  padding: 12,
                  border: '1px solid #d1d5db',
                  borderRadius: 6,
                  fontSize: 14
                }}
              >
                <option value="">Select a mentoring pair</option>
                {pairs.map(pair => (
                  <option key={pair.id} value={pair.id}>
                    {pair.mentor?.full_name || pair.mentor?.email} → {pair.mentee?.full_name || pair.mentee?.email}
                  </option>
                ))}
              </select>
            </div>

            <div style={{ marginBottom: 16 }}>
              <label style={{
                display: 'block',
                marginBottom: 4,
                fontSize: 14,
                fontWeight: 500,
                color: '#374151'
              }}>
                Title
              </label>
              <input
                type="text"
                value={newGoal.title}
                onChange={e => setNewGoal({...newGoal, title: e.target.value})}
                placeholder="Enter goal title"
                required
                style={{
                  width: '100%',
                  padding: 12,
                  border: '1px solid #d1d5db',
                  borderRadius: 6,
                  fontSize: 14
                }}
              />
            </div>

            <div style={{ marginBottom: 16 }}>
              <label style={{
                display: 'block',
                marginBottom: 4,
                fontSize: 14,
                fontWeight: 500,
                color: '#374151'
              }}>
                Description
              </label>
              <textarea
                value={newGoal.description}
                onChange={e => setNewGoal({...newGoal, description: e.target.value})}
                placeholder="Describe the goal..."
                rows={3}
                style={{
                  width: '100%',
                  padding: 12,
                  border: '1px solid #d1d5db',
                  borderRadius: 6,
                  fontSize: 14,
                  resize: 'vertical'
                }}
              />
            </div>

            <div style={{ marginBottom: 24 }}>
              <label style={{
                display: 'block',
                marginBottom: 4,
                fontSize: 14,
                fontWeight: 500,
                color: '#374151'
              }}>
                Target Date (optional)
              </label>
              <input
                type="date"
                value={newGoal.target_date}
                onChange={e => setNewGoal({...newGoal, target_date: e.target.value})}
                style={{
                  width: '100%',
                  padding: 12,
                  border: '1px solid #d1d5db',
                  borderRadius: 6,
                  fontSize: 14
                }}
              />
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
                Create Goal
              </button>
              <button
                type="button"
                onClick={() => setShowAddForm(false)}
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

      {goals.length === 0 ? (
        <div style={{
          background: 'white',
          padding: 40,
          borderRadius: 12,
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          textAlign: 'center'
        }}>
          <Target size={48} color="#9ca3af" style={{ margin: '0 auto 16px' }} />
          <h3 style={{
            fontSize: 18,
            fontWeight: 600,
            color: '#374151',
            margin: '0 0 8px 0'
          }}>
            No goals yet
          </h3>
          <p style={{
            color: '#64748b',
            margin: 0,
            fontSize: 14
          }}>
            Create your first goal to start tracking progress with your mentor or mentee.
          </p>
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 16 }}>
          {goals.map(goal => {
            const pair = pairs.find(p => p.id === goal.pair_id);
            return (
              <div
                key={goal.id}
                style={{
                  background: 'white',
                  padding: 20,
                  borderRadius: 12,
                  boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
                  borderLeft: `4px solid ${goal.status === 'completed' ? '#22c55e' : goal.status === 'in_progress' ? '#f59e0b' : '#6b7280'}`
                }}
              >
                <div style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'flex-start',
                  marginBottom: 12
                }}>
                  <div style={{ flex: 1 }}>
                    <h3 style={{
                      fontSize: 16,
                      fontWeight: 600,
                      color: '#374151',
                      margin: '0 0 4px 0'
                    }}>
                      {goal.title}
                    </h3>
                    {pair && (
                      <p style={{
                        fontSize: 12,
                        color: '#64748b',
                        margin: '0 0 8px 0'
                      }}>
                        {pair.mentor?.full_name || pair.mentor?.email} → {pair.mentee?.full_name || pair.mentee?.email}
                      </p>
                    )}
                    {goal.description && (
                      <p style={{
                        fontSize: 14,
                        color: '#64748b',
                        margin: '0 0 12px 0'
                      }}>
                        {goal.description}
                      </p>
                    )}
                    {goal.target_date && (
                      <p style={{
                        fontSize: 12,
                        color: '#64748b',
                        margin: 0
                      }}>
                        Target: {new Date(goal.target_date).toLocaleDateString()}
                      </p>
                    )}
                  </div>
                  
                  <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 8,
                    background: getStatusColor(goal.status),
                    padding: '4px 12px',
                    borderRadius: 20,
                    fontSize: 12,
                    fontWeight: 500,
                    color: '#374151'
                  }}>
                    {getStatusIcon(goal.status)}
                    {goal.status.replace('_', ' ').toUpperCase()}
                  </div>
                </div>

                <div style={{
                  display: 'flex',
                  gap: 8,
                  marginTop: 16
                }}>
                  {goal.status !== 'not_started' && (
                    <button
                      onClick={() => updateGoalStatus(goal.id, 'not_started')}
                      style={{
                        padding: '6px 12px',
                        background: '#f3f4f6',
                        color: '#374151',
                        border: 'none',
                        borderRadius: 4,
                        cursor: 'pointer',
                        fontSize: 12,
                        fontWeight: 500
                      }}
                    >
                      Not Started
                    </button>
                  )}
                  {goal.status !== 'in_progress' && (
                    <button
                      onClick={() => updateGoalStatus(goal.id, 'in_progress')}
                      style={{
                        padding: '6px 12px',
                        background: '#fef3c7',
                        color: '#92400e',
                        border: 'none',
                        borderRadius: 4,
                        cursor: 'pointer',
                        fontSize: 12,
                        fontWeight: 500
                      }}
                    >
                      In Progress
                    </button>
                  )}
                  {goal.status !== 'completed' && (
                    <button
                      onClick={() => updateGoalStatus(goal.id, 'completed')}
                      style={{
                        padding: '6px 12px',
                        background: '#dcfce7',
                        color: '#166534',
                        border: 'none',
                        borderRadius: 4,
                        cursor: 'pointer',
                        fontSize: 12,
                        fontWeight: 500
                      }}
                    >
                      Completed
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

export const Goals = React.memo(GoalsComponent);