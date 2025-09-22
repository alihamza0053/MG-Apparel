import React, { useState, useEffect, useCallback } from 'react';
import { supabase } from '../supabaseClient';
import { useAuth } from '../AuthContext';
import { Plus, Target, Clock, CheckCircle, Circle, Calendar, Users, BookOpen } from 'lucide-react';
import { format } from 'date-fns';

// Session interface
interface Session {
  id: string;
  session_number: number;
  title: string;
  description: string;
  duration_weeks: number;
  is_active: boolean;
}

// Updated Goal interface for session-based goals
interface SessionGoal {
  id: string;
  created_at: string;
  updated_at: string;
  title: string;
  description: string;
  session_id: string;
  mentor_id?: string;
  mentee_id?: string;
  pair_id: string;
  target_date?: string;
  priority: 'low' | 'medium' | 'high';
  status: 'not_started' | 'in_progress' | 'completed' | 'paused';
  progress_percentage: number;
  notes?: string;
  is_mentor_created: boolean;
  is_mentee_created: boolean;
}

interface MentoringPair {
  id: string;
  mentor_id: string;
  mentee_id: string;
  status: string;
  mentor?: {
    id: string;
    full_name: string;
    email: string;
  };
  mentee?: {
    id: string;
    full_name: string;
    email: string;
  };
}

const SessionBasedGoals: React.FC = () => {
  const { user } = useAuth();
  const [sessions, setSessions] = useState<Session[]>([]);
  const [goals, setGoals] = useState<SessionGoal[]>([]);
  const [pairs, setPairs] = useState<MentoringPair[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedSession, setSelectedSession] = useState<string>('');
  const [selectedPair, setSelectedPair] = useState<string>('');
  const [showAddForm, setShowAddForm] = useState(false);
  const [showAddSessionForm, setShowAddSessionForm] = useState(false);
  const [newGoal, setNewGoal] = useState({
    title: '',
    description: '',
    target_date: '',
    priority: 'medium' as 'low' | 'medium' | 'high',
    notes: ''
  });
  const [newSession, setNewSession] = useState({
    session_number: 0,
    title: '',
    description: '',
    duration_weeks: 2
  });

  // Fetch sessions (6 pre-defined sessions)
  const fetchSessions = useCallback(async () => {
    try {
      const { data, error } = await supabase
        .from('sessions')
        .select('*')
        .eq('is_active', true)
        .order('session_number', { ascending: true });

      if (error) {
        console.error('Error fetching sessions:', error);
        if (error.code === 'PGRST116' || error.message.includes('relation "sessions" does not exist')) {
          console.log('Sessions table does not exist. Please run the database migration.');
          // Create a fallback session for demo purposes
          setSessions([{
            id: 'temp-1',
            session_number: 1,
            title: 'Getting Started & Goal Setting',
            description: 'Please run the database migration to create the sessions table.',
            duration_weeks: 2,
            is_active: true
          }]);
        } else {
          throw error;
        }
        return;
      }

      setSessions(data || []);
      
      // Auto-select first session if none selected
      if (data && data.length > 0 && !selectedSession) {
        setSelectedSession(data[0].id);
      }
    } catch (error) {
      console.error('Error fetching sessions:', error);
    }
  }, [selectedSession]);

  // Fetch mentoring pairs
  const fetchPairs = useCallback(async () => {
    try {
      if (user?.role === 'admin') {
        // Admin can see all pairs
        const { data, error } = await supabase
          .from('mentoring_pairs')
          .select(`
            *,
            mentor:profiles!mentor_id(id, full_name, email),
            mentee:profiles!mentee_id(id, full_name, email)
          `)
          .eq('status', 'active')
          .order('created_at', { ascending: false });

        if (error) throw error;
        setPairs(data || []);
      } else {
        // Fetch pairs for current user
        const { data, error } = await supabase
          .from('mentoring_pairs')
          .select(`
            *,
            mentor:profiles!mentor_id(id, full_name, email),
            mentee:profiles!mentee_id(id, full_name, email)
          `)
          .or(`mentor_id.eq.${user?.id},mentee_id.eq.${user?.id}`)
          .eq('status', 'active');

        if (error) throw error;
        setPairs(data || []);
        
        // Auto-select first pair if none selected
        if (data && data.length > 0 && !selectedPair) {
          setSelectedPair(data[0].id);
        }
      }
    } catch (error) {
      console.error('Error fetching pairs:', error);
    }
  }, [user?.id, user?.role, selectedPair]);

  // Fetch goals for selected session and pair
  const fetchGoals = useCallback(async () => {
    try {
      if (!selectedSession || (!selectedPair && user?.role !== 'admin')) {
        setGoals([]);
        return;
      }

      let query = supabase
        .from('goals')
        .select(`
          *,
          session:sessions(session_number, title),
          pair:mentoring_pairs(
            id,
            mentor:profiles!mentor_id(full_name),
            mentee:profiles!mentee_id(full_name)
          )
        `)
        .eq('session_id', selectedSession);

      if (user?.role !== 'admin' && selectedPair) {
        query = query.eq('pair_id', selectedPair);
      }

      const { data, error } = await query.order('created_at', { ascending: false });

      if (error) throw error;
      setGoals(data || []);
    } catch (error) {
      console.error('Error fetching goals:', error);
    }
  }, [selectedSession, selectedPair, user?.role]);

  // Main data fetching effect
  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      await Promise.all([fetchSessions(), fetchPairs()]);
      setLoading(false);
    };
    
    if (user?.id) {
      fetchData();
    }
  }, [user?.id, fetchSessions, fetchPairs]);

  // Fetch goals when session or pair changes
  useEffect(() => {
    if (selectedSession && (selectedPair || user?.role === 'admin')) {
      fetchGoals();
    }
  }, [selectedSession, selectedPair, fetchGoals, user?.role]);

  const handleAddGoal = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (!selectedSession || !selectedPair) {
        alert('Please select a session and mentoring pair');
        return;
      }

      const pair = pairs.find(p => p.id === selectedPair);
      if (!pair) {
        alert('Selected pair not found');
        return;
      }

      const isMentor = user?.id === pair.mentor_id;
      const isMentee = user?.id === pair.mentee_id;

      console.log('Adding goal with data:', {
        ...newGoal,
        session_id: selectedSession,
        pair_id: selectedPair,
        mentor_id: pair.mentor_id,
        mentee_id: pair.mentee_id,
        is_mentor_created: isMentor,
        is_mentee_created: isMentee,
        status: 'not_started'
      });

      const { data, error } = await supabase
        .from('goals')
        .insert([{
          ...newGoal,
          session_id: selectedSession,
          pair_id: selectedPair,
          mentor_id: pair.mentor_id,
          mentee_id: pair.mentee_id,
          is_mentor_created: isMentor,
          is_mentee_created: isMentee,
          status: 'not_started'
        }])
        .select();

      if (error) {
        console.error('Detailed error:', error);
        alert(`Error adding goal: ${error.message}\nCode: ${error.code}\nDetails: ${error.details || 'No additional details'}`);
        return;
      }

      console.log('Goal added successfully:', data);

      // Reset form
      setNewGoal({
        title: '',
        description: '',
        target_date: '',
        priority: 'medium',
        notes: ''
      });
      setShowAddForm(false);
      
      // Refresh goals
      fetchGoals();
      alert('Goal added successfully!');
    } catch (error) {
      console.error('Error adding goal:', error);
      alert('Error adding goal. Please try again.');
    }
  };

  const handleAddSession = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (!newSession.title || !newSession.description) {
        alert('Please fill in all required fields');
        return;
      }

      console.log('Creating new session:', newSession);

      // Get the next session number
      const maxSessionNumber = Math.max(...sessions.map(s => s.session_number), 0);
      const nextSessionNumber = maxSessionNumber + 1;

      console.log('Next session number:', nextSessionNumber);

      const sessionData = {
        session_number: nextSessionNumber,
        title: newSession.title,
        description: newSession.description,
        duration_weeks: newSession.duration_weeks,
        is_active: true
      };

      console.log('Inserting session data:', sessionData);

      const { data, error } = await supabase
        .from('sessions')
        .insert([sessionData])
        .select();

      console.log('Supabase response:', { data, error });

      if (error) {
        console.error('Supabase error details:', error);
        alert(`Error creating session: ${error.message}\nCode: ${error.code}\nDetails: ${error.details}`);
        return;
      }

      console.log('Session created successfully:', data);

      // Reset form
      setNewSession({
        session_number: 0,
        title: '',
        description: '',
        duration_weeks: 2
      });
      setShowAddSessionForm(false);
      
      // Refresh sessions
      await fetchSessions();
      alert('Session added successfully!');
    } catch (error) {
      console.error('Error adding session:', error);
      alert('Error adding session. Please try again.');
    }
  };

  // Handle session removal
  const handleRemoveSession = async (sessionId: string, sessionTitle: string) => {
    if (!confirm(`Are you sure you want to remove the session "${sessionTitle}"? This will also remove all associated goals and feedback.`)) {
      return;
    }

    try {
      // First remove associated goals
      const { error: goalsError } = await supabase
        .from('goals')
        .delete()
        .eq('session_id', sessionId);

      if (goalsError) {
        console.error('Error removing session goals:', goalsError);
        alert(`Error removing session goals: ${goalsError.message}`);
        return;
      }

      // Then remove associated feedback
      const { error: feedbackError } = await supabase
        .from('feedback')
        .delete()
        .eq('session_id', sessionId);

      if (feedbackError) {
        console.error('Error removing session feedback:', feedbackError);
        alert(`Error removing session feedback: ${feedbackError.message}`);
        return;
      }

      // Finally remove the session
      const { error: sessionError } = await supabase
        .from('sessions')
        .delete()
        .eq('id', sessionId);

      if (sessionError) {
        console.error('Error removing session:', sessionError);
        alert(`Error removing session: ${sessionError.message}`);
        return;
      }

      // Refresh sessions
      await fetchSessions();
      
      // If the removed session was selected, clear selection
      if (selectedSession === sessionId) {
        setSelectedSession('');
      }
      
      alert('Session removed successfully!');
    } catch (error) {
      console.error('Error removing session:', error);
      alert('Error removing session. Please try again.');
    }
  };

  // Handle goal status update
  const handleUpdateGoalStatus = async (goalId: string, newStatus: 'not_started' | 'in_progress' | 'completed' | 'paused') => {
    try {
      const { error } = await supabase
        .from('goals')
        .update({ status: newStatus })
        .eq('id', goalId);

      if (error) {
        console.error('Error updating goal status:', error);
        alert(`Error updating goal status: ${error.message}`);
        return;
      }

      // Refresh goals
      await fetchGoals();
    } catch (error) {
      console.error('Error updating goal status:', error);
      alert('Error updating goal status. Please try again.');
    }
  };

  // Handle goal priority update
  const handleUpdateGoalPriority = async (goalId: string, newPriority: 'low' | 'medium' | 'high') => {
    try {
      const { error } = await supabase
        .from('goals')
        .update({ priority: newPriority })
        .eq('id', goalId);

      if (error) {
        console.error('Error updating goal priority:', error);
        alert(`Error updating goal priority: ${error.message}`);
        return;
      }

      // Refresh goals
      await fetchGoals();
    } catch (error) {
      console.error('Error updating goal priority:', error);
      alert('Error updating goal priority. Please try again.');
    }
  };

  const updateGoalStatus = async (goalId: string, newStatus: string, progressPercentage?: number) => {
    try {
      const updateData: any = { 
        status: newStatus,
        updated_at: new Date().toISOString()
      };
      
      if (progressPercentage !== undefined) {
        updateData.progress_percentage = progressPercentage;
      }

      const { error } = await supabase
        .from('goals')
        .update(updateData)
        .eq('id', goalId);

      if (error) throw error;
      fetchGoals();
    } catch (error) {
      console.error('Error updating goal:', error);
    }
  };

  const deleteGoal = async (goalId: string) => {
    if (!confirm('Are you sure you want to delete this goal?')) return;
    
    try {
      const { error } = await supabase
        .from('goals')
        .delete()
        .eq('id', goalId);

      if (error) throw error;
      fetchGoals();
      alert('Goal deleted successfully!');
    } catch (error) {
      console.error('Error deleting goal:', error);
      alert('Error deleting goal. Please try again.');
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'in_progress':
        return <Clock className="w-5 h-5 text-blue-500" />;
      case 'paused':
        return <span className="w-5 h-5 text-yellow-500 flex items-center justify-center text-xs font-bold">||</span>;
      default:
        return <Circle className="w-5 h-5 text-gray-400" />;
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high':
        return 'bg-red-100 text-red-800 border-red-200';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'low':
        return 'bg-green-100 text-green-800 border-green-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const selectedSessionData = sessions.find(s => s.id === selectedSession);
  const selectedPairData = pairs.find(p => p.id === selectedPair);

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  // Check if database needs setup
  const needsDatabaseSetup = sessions.length === 0 || sessions.some(s => s.id.startsWith('temp-'));

  if (needsDatabaseSetup) {
    return (
      <div className="p-6 max-w-4xl mx-auto">
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6">
          <h2 className="text-xl font-semibold text-yellow-800 mb-4">Database Setup Required</h2>
          <p className="text-yellow-700 mb-4">
            The sessions table needs to be created in your database. Please run the following SQL script in your Supabase SQL Editor:
          </p>
          <div className="bg-gray-800 text-gray-100 p-4 rounded text-sm font-mono overflow-x-auto mb-4">
            <p>-- Copy and paste the contents of 'create_sessions_table.sql' into your Supabase SQL Editor</p>
            <p>-- File location: /create_sessions_table.sql</p>
          </div>
          <p className="text-yellow-600 text-sm">
            After running the script, refresh this page to continue.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 max-w-6xl mx-auto">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold text-gray-800 flex items-center space-x-2">
          <Target className="w-8 h-8" />
          <span>Session-Based Goals</span>
        </h1>
        
        <div className="flex space-x-2">
          {/* Add Session Button */}
          <button
            onClick={() => setShowAddSessionForm(true)}
            className="bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded-lg flex items-center space-x-2"
          >
            <Plus className="w-4 h-4" />
            <span>Add Session</span>
          </button>
        </div>
      </div>

      {/* Session Selection */}
      <div className="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 className="text-xl font-semibold mb-4 flex items-center space-x-2">
          <BookOpen className="w-5 h-5" />
          <span>Select Session</span>
        </h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-4">
          {sessions.map((session) => (
            <div
              key={session.id}
              className={`p-4 rounded-lg border-2 transition-all ${
                selectedSession === session.id
                  ? 'border-blue-500 bg-blue-50'
                  : 'border-gray-200 hover:border-gray-300 bg-white'
              }`}
            >
              <div 
                onClick={() => setSelectedSession(session.id)}
                className="cursor-pointer"
              >
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center space-x-2">
                    <span className="bg-blue-100 text-blue-800 px-2 py-1 rounded text-sm font-medium">
                      Session {session.session_number}
                    </span>
                  </div>
                  
                  <div className="flex items-center space-x-2">
                    {/* Close button for all users */}
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleRemoveSession(session.id, session.title);
                      }}
                      className="text-gray-400 hover:text-red-500 text-lg font-bold leading-none w-6 h-6 flex items-center justify-center"
                      title="Remove Session"
                    >
                      ×
                    </button>
                  </div>
                </div>
                <h3 className="font-semibold text-gray-800 mb-2">{session.title}</h3>
                <p className="text-gray-600 text-sm mb-3">{session.description}</p>
                <div className="text-xs text-gray-500 mb-3">
                  Duration: {session.duration_weeks} weeks
                </div>
              </div>
              
              {/* Add Goals button for each session */}
              {(selectedPair || user?.role === 'admin') && (
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    setSelectedSession(session.id);
                    setShowAddForm(true);
                  }}
                  className="w-full bg-blue-500 hover:bg-blue-600 text-white px-3 py-2 rounded text-sm flex items-center justify-center space-x-1"
                >
                  <Plus className="w-3 h-3" />
                  <span>Add Goals</span>
                </button>
              )}
            </div>
          ))}
        </div>

        {selectedSessionData && (
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <div className="flex justify-between items-start">
              <div>
                <h3 className="font-semibold text-blue-800 mb-2">
                  📋 Current Session: Session {selectedSessionData.session_number} - {selectedSessionData.title}
                </h3>
                <p className="text-blue-700 text-sm mb-2">{selectedSessionData.description}</p>
                <p className="text-blue-600 text-xs">Duration: {selectedSessionData.duration_weeks} weeks</p>
              </div>
              <div className="text-right">
                <div className="bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-xs font-medium">
                  Active Session
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Pair Selection (if admin or multiple pairs) */}
      {(user?.role === 'admin' || pairs.length > 1) && (
        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h2 className="text-xl font-semibold mb-4 flex items-center space-x-2">
            <Users className="w-5 h-5" />
            <span>Select Mentoring Pair</span>
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {pairs.map((pair) => (
              <div
                key={pair.id}
                onClick={() => setSelectedPair(pair.id)}
                className={`p-4 rounded-lg border-2 cursor-pointer transition-all ${
                  selectedPair === pair.id
                    ? 'border-green-500 bg-green-50'
                    : 'border-gray-200 hover:border-gray-300 bg-white'
                }`}
              >
                <div className="flex justify-between items-center">
                  <div>
                    <div className="font-medium text-gray-800">
                      {pair.mentor?.full_name || 'Unknown Mentor'}
                    </div>
                    <div className="text-gray-600 text-sm">
                      mentoring {pair.mentee?.full_name || 'Unknown Mentee'}
                    </div>
                  </div>
                  <div className={`px-2 py-1 rounded text-xs font-medium ${
                    pair.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                  }`}>
                    {pair.status}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Goals Display */}
      {selectedSession && (selectedPair || user?.role === 'admin') && (
        <div className="bg-white rounded-lg shadow-md p-6">
          <div className="flex justify-between items-center mb-6">
            <div>
              <h2 className="text-xl font-semibold flex items-center space-x-2">
                <Target className="w-5 h-5 text-blue-500" />
                <span>Goals for Session {selectedSessionData?.session_number}: {selectedSessionData?.title}</span>
              </h2>
              {selectedPairData && (
                <p className="text-gray-600 text-sm mt-1">
                  Mentor: <span className="font-medium">{selectedPairData.mentor?.full_name}</span> → 
                  Mentee: <span className="font-medium">{selectedPairData.mentee?.full_name}</span>
                </p>
              )}
            </div>
            <div className="text-right">
              <span className="text-gray-500 text-sm block">
                {goals.length} goal{goals.length !== 1 ? 's' : ''}
              </span>
              <button
                onClick={() => setShowAddForm(true)}
                className="mt-2 bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded text-sm flex items-center space-x-1"
              >
                <Plus className="w-3 h-3" />
                <span>Add Goal</span>
              </button>
            </div>
          </div>

          {goals.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              <Target className="w-12 h-12 mx-auto mb-4 text-gray-300" />
              <p>No goals set for this session yet.</p>
              <p className="text-sm">Click "Add Goal" to create your first goal.</p>
            </div>
          ) : (
            <div className="space-y-4">
              {goals.map((goal) => (
                <div key={goal.id} className="border border-gray-200 rounded-lg p-4 hover:shadow-sm transition-shadow">
                  <div className="flex justify-between items-start mb-3">
                    <div className="flex items-center space-x-3">
                      {getStatusIcon(goal.status)}
                      <div>
                        <h3 className="font-medium text-gray-800">{goal.title}</h3>
                        <p className="text-gray-600 text-sm">{goal.description}</p>
                      </div>
                    </div>
                    
                    <div className="flex items-center space-x-2">
                      {/* Priority Selector */}
                      <select
                        value={goal.priority}
                        onChange={(e) => handleUpdateGoalPriority(goal.id, e.target.value as 'low' | 'medium' | 'high')}
                        className={`px-2 py-1 rounded text-xs font-medium border cursor-pointer ${getPriorityColor(goal.priority)}`}
                      >
                        <option value="low">Low</option>
                        <option value="medium">Medium</option>
                        <option value="high">High</option>
                      </select>
                      
                      {/* Status Selector */}
                      <select
                        value={goal.status}
                        onChange={(e) => handleUpdateGoalStatus(goal.id, e.target.value as 'not_started' | 'in_progress' | 'completed' | 'paused')}
                        className={`px-2 py-1 rounded text-xs font-medium cursor-pointer ${
                          goal.status === 'completed' ? 'bg-green-100 text-green-800' :
                          goal.status === 'in_progress' ? 'bg-blue-100 text-blue-800' :
                          goal.status === 'paused' ? 'bg-yellow-100 text-yellow-800' :
                          'bg-gray-100 text-gray-800'
                        }`}
                      >
                        <option value="not_started">Not Started</option>
                        <option value="in_progress">In Progress</option>
                        <option value="paused">Paused</option>
                        <option value="completed">Completed</option>
                      </select>
                    </div>
                  </div>

                  <div className="flex justify-between items-center text-sm text-gray-500">
                    <div className="flex items-center space-x-4">
                      {goal.target_date && (
                        <div className="flex items-center space-x-1">
                          <Calendar className="w-4 h-4" />
                          <span>Due: {format(new Date(goal.target_date), 'MMM dd, yyyy')}</span>
                        </div>
                      )}
                      <span>
                        Created by: {goal.is_mentor_created ? 'Mentor' : 'Mentee'}
                      </span>
                    </div>
                    
                    <div className="flex items-center space-x-2">
                      <button
                        onClick={() => deleteGoal(goal.id)}
                        className="text-red-500 hover:text-red-700 text-xs px-2 py-1 border border-red-300 rounded hover:bg-red-50"
                      >
                        Delete
                      </button>
                    </div>
                  </div>

                  {goal.notes && (
                    <div className="mt-3 p-3 bg-gray-50 rounded border-l-4 border-blue-400">
                      <p className="text-sm text-gray-700">{goal.notes}</p>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Add Goal Form Modal */}
      {showAddForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md mx-4">
            <h2 className="text-xl font-semibold mb-4">Add New Goal</h2>
            <form onSubmit={handleAddGoal} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Goal Title *
                </label>
                <input
                  type="text"
                  value={newGoal.title}
                  onChange={(e) => setNewGoal({ ...newGoal, title: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Description
                </label>
                <textarea
                  value={newGoal.description}
                  onChange={(e) => setNewGoal({ ...newGoal, description: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows={3}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Target Date
                </label>
                <input
                  type="date"
                  value={newGoal.target_date}
                  onChange={(e) => setNewGoal({ ...newGoal, target_date: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Priority
                </label>
                <select
                  value={newGoal.priority}
                  onChange={(e) => setNewGoal({ ...newGoal, priority: e.target.value as 'low' | 'medium' | 'high' })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="low">Low</option>
                  <option value="medium">Medium</option>
                  <option value="high">High</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Notes
                </label>
                <textarea
                  value={newGoal.notes}
                  onChange={(e) => setNewGoal({ ...newGoal, notes: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows={2}
                  placeholder="Additional notes or details..."
                />
              </div>

              <div className="flex justify-end space-x-3 pt-4">
                <button
                  type="button"
                  onClick={() => setShowAddForm(false)}
                  className="px-4 py-2 text-gray-600 border border-gray-300 rounded-md hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600"
                >
                  Add Goal
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add Session Form Modal */}
      {showAddSessionForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md mx-4">
            <h2 className="text-xl font-semibold mb-4">Add New Session</h2>
            <form onSubmit={handleAddSession} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Session Title *
                </label>
                <input
                  type="text"
                  value={newSession.title}
                  onChange={(e) => setNewSession({ ...newSession, title: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="e.g., Advanced Skills Development"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Description *
                </label>
                <textarea
                  value={newSession.description}
                  onChange={(e) => setNewSession({ ...newSession, description: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows={3}
                  placeholder="Describe what this session will cover..."
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Duration (weeks)
                </label>
                <input
                  type="number"
                  min="1"
                  max="12"
                  value={newSession.duration_weeks}
                  onChange={(e) => setNewSession({ ...newSession, duration_weeks: parseInt(e.target.value) || 2 })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="text-sm text-gray-600 bg-blue-50 p-3 rounded">
                <strong>Note:</strong> This will be automatically assigned as Session {Math.max(...sessions.map(s => s.session_number), 0) + 1}
              </div>

              <div className="flex justify-end space-x-3 pt-4">
                <button
                  type="button"
                  onClick={() => setShowAddSessionForm(false)}
                  className="px-4 py-2 text-gray-600 border border-gray-300 rounded-md hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-green-500 text-white rounded-md hover:bg-green-600"
                >
                  Add Session
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default SessionBasedGoals;