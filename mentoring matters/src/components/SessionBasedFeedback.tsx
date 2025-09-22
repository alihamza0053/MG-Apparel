import React, { useState, useEffect, useCallback } from 'react';
import { supabase } from '../supabaseClient';
import { useAuth } from '../AuthContext';
import { Star, MessageCircle, Calendar, User, Search, Plus, BookOpen, Users, CheckCircle } from 'lucide-react';
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

// Updated Feedback interface for session-based feedback
interface SessionFeedback {
  id: string;
  created_at: string;
  session_id: string;
  session_date: string;
  rating: number;
  comments: string;
  mentor_feedback?: string;
  mentee_feedback?: string;
  mentor_id?: string;
  mentee_id?: string;
  pair_id: string;
  session_completed: boolean;
  next_session_goals?: string;
  feedback_type: 'session' | 'overall';
  session?: {
    session_number: number;
    title: string;
  };
  mentor?: {
    full_name: string;
    avatar_url?: string;
  };
  mentee?: {
    full_name: string;
    avatar_url?: string;
  };
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

interface NewSessionFeedback {
  session_id: string;
  session_date: string;
  rating: number;
  comments: string;
  mentor_feedback: string;
  mentee_feedback: string;
  pair_id: string;
  session_completed: boolean;
  next_session_goals: string;
}

const SessionBasedFeedback: React.FC = () => {
  const { user } = useAuth();
  const [sessions, setSessions] = useState<Session[]>([]);
  const [feedback, setFeedback] = useState<SessionFeedback[]>([]);
  const [pairs, setPairs] = useState<MentoringPair[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [selectedSession, setSelectedSession] = useState<string>('');
  const [selectedPair, setSelectedPair] = useState<string>('');
  const [newFeedback, setNewFeedback] = useState<NewSessionFeedback>({
    session_id: '',
    session_date: '',
    rating: 5,
    comments: '',
    mentor_feedback: '',
    mentee_feedback: '',
    pair_id: '',
    session_completed: false,
    next_session_goals: ''
  });

  // Fetch sessions
  const fetchSessions = useCallback(async () => {
    try {
      const { data, error } = await supabase
        .from('sessions')
        .select('*')
        .eq('is_active', true)
        .order('session_number', { ascending: true });

      if (error) throw error;
      setSessions(data || []);
    } catch (error) {
      console.error('Error fetching sessions:', error);
    }
  }, []);

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

  // Fetch feedback data
  const fetchFeedback = useCallback(async () => {
    try {
      // First get all profiles for lookup
      const { data: profilesForLookup, error: profileError } = await supabase
        .from('profiles')
        .select('id, full_name, avatar_url, role');

      if (profileError) throw profileError;

      // Create a lookup map
      const profileMap = new Map();
      if (profilesForLookup) {
        profilesForLookup.forEach(profile => {
          profileMap.set(profile.id, profile);
        });
      }

      // Get feedback data with session information
      let query = supabase
        .from('feedback')
        .select(`
          id,
          created_at,
          session_id,
          session_date,
          rating,
          comments,
          mentor_feedback,
          mentee_feedback,
          mentor_id,
          mentee_id,
          pair_id,
          session_completed,
          next_session_goals,
          feedback_type,
          session:sessions(session_number, title)
        `)
        .order('created_at', { ascending: false });

      // Filter by user role
      if (user?.role !== 'admin') {
        query = query.or(`mentor_id.eq.${user?.id},mentee_id.eq.${user?.id}`);
      }

      const { data, error } = await query;

      if (error) throw error;

      // Process feedback with profile lookup
      if (data && data.length > 0) {
        const feedbackWithProfiles = data.map((feedback: any) => {
          let mentor = null;
          let mentee = null;

          if (feedback.mentor_id && feedback.mentee_id) {
            mentor = profileMap.get(feedback.mentor_id);
            mentee = profileMap.get(feedback.mentee_id);
          }

          return {
            ...feedback,
            mentor: mentor || { full_name: 'Unknown Mentor', avatar_url: null },
            mentee: mentee || { full_name: 'Unknown Mentee', avatar_url: null }
          };
        });

        setFeedback(feedbackWithProfiles);
      } else {
        setFeedback([]);
      }
    } catch (error) {
      console.error('Error in fetchFeedback:', error);
      setFeedback([]);
    }
  }, [user?.id, user?.role]);

  // Main data fetching effect
  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      await Promise.all([fetchSessions(), fetchPairs(), fetchFeedback()]);
      setLoading(false);
    };
    
    if (user?.id) {
      fetchData();
    }
  }, [user?.id, fetchSessions, fetchPairs, fetchFeedback]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (!newFeedback.session_id || !newFeedback.session_date || !newFeedback.comments || !newFeedback.pair_id) {
        alert('Please fill in all required fields: session, date, comments, and mentoring pair');
        return;
      }

      // Get mentor and mentee IDs from the selected pair
      const selectedPairData = pairs.find(pair => pair.id === newFeedback.pair_id);
      if (!selectedPairData) {
        alert('Please select a valid mentor-mentee pair');
        return;
      }

      const isMentor = user?.id === selectedPairData.mentor_id;
      const isMentee = user?.id === selectedPairData.mentee_id;

      const { data, error } = await supabase
        .from('feedback')
        .insert([{
          session_id: newFeedback.session_id,
          session_date: newFeedback.session_date,
          rating: newFeedback.rating,
          comments: newFeedback.comments,
          mentor_feedback: isMentor ? newFeedback.mentor_feedback : null,
          mentee_feedback: isMentee ? newFeedback.mentee_feedback : null,
          mentor_id: selectedPairData.mentor_id,
          mentee_id: selectedPairData.mentee_id,
          pair_id: newFeedback.pair_id,
          session_completed: newFeedback.session_completed,
          next_session_goals: newFeedback.next_session_goals,
          feedback_type: 'session'
        }])
        .select();

      if (error) {
        console.error('Supabase error:', error);
        alert('Error submitting feedback: ' + error.message);
        return;
      }

      console.log('Feedback added successfully:', data);
      alert('Session feedback submitted successfully!');
      
      setNewFeedback({
        session_id: '',
        session_date: '',
        rating: 5,
        comments: '',
        mentor_feedback: '',
        mentee_feedback: '',
        pair_id: '',
        session_completed: false,
        next_session_goals: ''
      });
      setShowForm(false);
      fetchFeedback();
    } catch (error) {
      console.error('Error creating feedback:', error);
      alert('Error adding feedback. Check console for details.');
    }
  };

  const renderStars = (rating: number) => {
    return Array.from({ length: 5 }, (_, index) => (
      <Star
        key={index}
        className={`w-4 h-4 ${
          index < rating ? 'text-yellow-400 fill-current' : 'text-gray-300'
        }`}
      />
    ));
  };

  const filteredFeedback = feedback.filter(item => {
    // First filter by selected session - if no session selected, show no feedback
    if (!selectedSession || item.session_id !== selectedSession) {
      return false;
    }
    
    // Then apply search filter
    const searchLower = searchTerm.toLowerCase();
    return (
      item.comments.toLowerCase().includes(searchLower) ||
      item.mentor?.full_name.toLowerCase().includes(searchLower) ||
      item.mentee?.full_name.toLowerCase().includes(searchLower) ||
      item.session?.title.toLowerCase().includes(searchLower)
    );
  });

  const selectedSessionData = sessions.find(s => s.id === newFeedback.session_id);
  const isMentor = user && pairs.some(p => p.id === newFeedback.pair_id && p.mentor_id === user.id);
  const isMentee = user && pairs.some(p => p.id === newFeedback.pair_id && p.mentee_id === user.id);

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  return (
    <div className="p-6 max-w-6xl mx-auto">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold text-gray-800 flex items-center space-x-2">
          <MessageCircle className="w-8 h-8" />
          <span>Session Feedback</span>
        </h1>
        
        <button
          onClick={() => setShowForm(true)}
          className="bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded-lg flex items-center space-x-2"
        >
          <Plus className="w-4 h-4" />
          <span>Quick Add Feedback</span>
        </button>
      </div>

      {/* Search Bar */}
      <div className="mb-6">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
          <input
            type="text"
            placeholder="Search feedback by comments, names, or session..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
      </div>

      {/* Sessions Overview with Add Feedback buttons */}
      <div className="bg-white rounded-lg shadow-md p-6 mb-6">
        <h2 className="text-xl font-semibold mb-4 flex items-center space-x-2">
          <BookOpen className="w-5 h-5" />
          <span>Mentoring Sessions</span>
        </h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {sessions.map((session) => {
            // Check if this session has feedback already
            const sessionFeedback = feedback.filter(f => f.session_id === session.id);
            const hasCompletedFeedback = sessionFeedback.some(f => f.session_completed);
            
            return (
              <div 
                key={session.id} 
                onClick={() => setSelectedSession(session.id)}
                className={`border rounded-lg p-4 hover:shadow-sm transition-shadow cursor-pointer ${
                  selectedSession === session.id 
                    ? 'border-blue-500 bg-blue-50 shadow-md' 
                    : 'border-gray-200'
                }`}
              >
                <div className="flex items-center space-x-2 mb-2">
                  <span className="bg-blue-100 text-blue-800 px-2 py-1 rounded text-sm font-medium">
                    Session {session.session_number}
                  </span>
                  {hasCompletedFeedback && (
                    <span className="bg-green-100 text-green-800 px-2 py-1 rounded text-xs font-medium flex items-center space-x-1">
                      <CheckCircle className="w-3 h-3" />
                      <span>Completed</span>
                    </span>
                  )}
                </div>
                
                <h3 className="font-semibold text-gray-800 mb-2">{session.title}</h3>
                <p className="text-gray-600 text-sm mb-3">{session.description}</p>
                
                <div className="flex items-center justify-between">
                  <span className="text-xs text-gray-500">
                    {sessionFeedback.length} feedback{sessionFeedback.length !== 1 ? 's' : ''}
                  </span>
                  
                  <button
                    onClick={() => {
                      setNewFeedback({ 
                        ...newFeedback, 
                        session_id: session.id,
                        session_date: new Date().toISOString().split('T')[0]
                      });
                      setShowForm(true);
                    }}
                    className="bg-blue-500 hover:bg-blue-600 text-white px-3 py-1 rounded text-sm flex items-center space-x-1"
                  >
                    <Plus className="w-3 h-3" />
                    <span>Add Feedback</span>
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Feedback List */}
      <div className="space-y-6">
        {selectedSession && (
          <div className="bg-white rounded-lg shadow-md p-4">
            <h3 className="text-lg font-semibold text-gray-800 flex items-center space-x-2">
              <MessageCircle className="w-5 h-5 text-blue-500" />
              <span>
                Feedback for Session {sessions.find(s => s.id === selectedSession)?.session_number}: {sessions.find(s => s.id === selectedSession)?.title}
              </span>
            </h3>
          </div>
        )}
        
        {!selectedSession ? (
          <div className="text-center py-12 bg-white rounded-lg shadow-md">
            <MessageCircle className="w-16 h-16 mx-auto text-gray-300 mb-4" />
            <h3 className="text-lg font-medium text-gray-700 mb-2">Select a Session</h3>
            <p className="text-gray-500 mb-4">Click on a session above to view its feedback.</p>
          </div>
        ) : filteredFeedback.length === 0 ? (
          <div className="text-center py-12 bg-white rounded-lg shadow-md">
            <MessageCircle className="w-16 h-16 mx-auto text-gray-300 mb-4" />
            <h3 className="text-lg font-medium text-gray-700 mb-2">No Feedback for This Session</h3>
            <p className="text-gray-500 mb-4">Start by adding feedback for this mentoring session.</p>
            <button
              onClick={() => {
                setNewFeedback({ 
                  ...newFeedback, 
                  session_id: selectedSession,
                  session_date: new Date().toISOString().split('T')[0]
                });
                setShowForm(true);
              }}
              className="bg-blue-500 hover:bg-blue-600 text-white px-6 py-3 rounded-lg"
            >
              Add First Session Feedback
            </button>
          </div>
        ) : (
          filteredFeedback.map((item) => (
            <div key={item.id} className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center space-x-4">
                  <div className="flex items-center space-x-2">
                    <BookOpen className="w-5 h-5 text-blue-500" />
                    <span className="font-semibold text-blue-600">
                      Session {item.session?.session_number}: {item.session?.title}
                    </span>
                  </div>
                  {item.session_completed && (
                    <div className="flex items-center space-x-1 text-green-600">
                      <CheckCircle className="w-4 h-4" />
                      <span className="text-sm font-medium">Completed</span>
                    </div>
                  )}
                </div>
                
                <div className="flex items-center space-x-2">
                  <Calendar className="w-4 h-4 text-gray-400" />
                  <span className="text-gray-600 text-sm">
                    {format(new Date(item.session_date), 'MMM dd, yyyy')}
                  </span>
                </div>
              </div>

              {/* Participants */}
              <div className="flex items-center space-x-4 mb-4 p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center space-x-2">
                  <User className="w-4 h-4 text-blue-500" />
                  <span className="text-sm font-medium text-gray-700">Mentor:</span>
                  <span className="text-sm text-gray-600">{item.mentor?.full_name}</span>
                </div>
                <div className="flex items-center space-x-2">
                  <User className="w-4 h-4 text-green-500" />
                  <span className="text-sm font-medium text-gray-700">Mentee:</span>
                  <span className="text-sm text-gray-600">{item.mentee?.full_name}</span>
                </div>
              </div>

              {/* Rating */}
              <div className="flex items-center space-x-2 mb-4">
                <span className="text-sm font-medium text-gray-700">Session Rating:</span>
                <div className="flex items-center space-x-1">
                  {renderStars(item.rating)}
                  <span className="text-sm text-gray-600 ml-2">({item.rating}/5)</span>
                </div>
              </div>

              {/* General Comments */}
              <div className="mb-4">
                <h4 className="font-medium text-gray-700 mb-2">Session Comments:</h4>
                <p className="text-gray-600 leading-relaxed bg-gray-50 p-3 rounded-lg">
                  {item.comments}
                </p>
              </div>

              {/* Role-specific Feedback */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                {item.mentor_feedback && (
                  <div>
                    <h4 className="font-medium text-blue-700 mb-2 flex items-center space-x-1">
                      <User className="w-4 h-4" />
                      <span>Mentor's Feedback:</span>
                    </h4>
                    <p className="text-gray-600 text-sm bg-blue-50 p-3 rounded-lg border-l-4 border-blue-400">
                      {item.mentor_feedback}
                    </p>
                  </div>
                )}
                
                {item.mentee_feedback && (
                  <div>
                    <h4 className="font-medium text-green-700 mb-2 flex items-center space-x-1">
                      <User className="w-4 h-4" />
                      <span>Mentee's Feedback:</span>
                    </h4>
                    <p className="text-gray-600 text-sm bg-green-50 p-3 rounded-lg border-l-4 border-green-400">
                      {item.mentee_feedback}
                    </p>
                  </div>
                )}
              </div>

              {/* Next Session Goals */}
              {item.next_session_goals && (
                <div className="mt-4">
                  <h4 className="font-medium text-gray-700 mb-2">Goals for Next Session:</h4>
                  <p className="text-gray-600 text-sm bg-yellow-50 p-3 rounded-lg border-l-4 border-yellow-400">
                    {item.next_session_goals}
                  </p>
                </div>
              )}

              <div className="flex justify-between items-center mt-4 pt-4 border-t border-gray-200">
                <span className="text-xs text-gray-400">
                  Submitted on {format(new Date(item.created_at), 'MMM dd, yyyy HH:mm')}
                </span>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Add Feedback Form Modal */}
      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl mx-4 max-h-[90vh] overflow-y-auto">
            <h2 className="text-xl font-semibold mb-4">
              {newFeedback.session_id && selectedSessionData 
                ? `Add Feedback for Session ${selectedSessionData.session_number}: ${selectedSessionData.title}`
                : 'Add Session Feedback'
              }
            </h2>
            <form onSubmit={handleSubmit} className="space-y-4">
              {/* Session Selection */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Session *
                </label>
                <select
                  value={newFeedback.session_id}
                  onChange={(e) => setNewFeedback({ ...newFeedback, session_id: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                >
                  <option value="">Select a session...</option>
                  {sessions.map((session) => (
                    <option key={session.id} value={session.id}>
                      Session {session.session_number}: {session.title}
                    </option>
                  ))}
                </select>
                {selectedSessionData && (
                  <p className="text-sm text-gray-600 mt-1">{selectedSessionData.description}</p>
                )}
              </div>

              {/* Pair Selection */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Mentoring Pair *
                </label>
                <select
                  value={newFeedback.pair_id}
                  onChange={(e) => setNewFeedback({ ...newFeedback, pair_id: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                >
                  <option value="">Select a mentoring pair...</option>
                  {pairs.map((pair) => (
                    <option key={pair.id} value={pair.id}>
                      {pair.mentor?.full_name} → {pair.mentee?.full_name}
                    </option>
                  ))}
                </select>
              </div>

              {/* Session Date */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Session Date *
                </label>
                <input
                  type="date"
                  value={newFeedback.session_date}
                  onChange={(e) => setNewFeedback({ ...newFeedback, session_date: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              {/* Rating */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Session Rating *
                </label>
                <div className="flex items-center space-x-2">
                  {[1, 2, 3, 4, 5].map((star) => (
                    <button
                      key={star}
                      type="button"
                      onClick={() => setNewFeedback({ ...newFeedback, rating: star })}
                      className="focus:outline-none"
                    >
                      <Star
                        className={`w-6 h-6 ${
                          star <= newFeedback.rating
                            ? 'text-yellow-400 fill-current'
                            : 'text-gray-300'
                        }`}
                      />
                    </button>
                  ))}
                  <span className="text-sm text-gray-600 ml-2">({newFeedback.rating}/5)</span>
                </div>
              </div>

              {/* General Comments */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Session Comments *
                </label>
                <textarea
                  value={newFeedback.comments}
                  onChange={(e) => setNewFeedback({ ...newFeedback, comments: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows={4}
                  placeholder="Share your thoughts about this session..."
                  required
                />
              </div>

              {/* Role-specific Feedback */}
              {(isMentor || isMentee) && (
                <div className="grid grid-cols-1 gap-4">
                  {isMentor && (
                    <div>
                      <label className="block text-sm font-medium text-blue-700 mb-1">
                        Mentor's Detailed Feedback
                      </label>
                      <textarea
                        value={newFeedback.mentor_feedback}
                        onChange={(e) => setNewFeedback({ ...newFeedback, mentor_feedback: e.target.value })}
                        className="w-full px-3 py-2 border border-blue-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        rows={3}
                        placeholder="As a mentor, share your perspective on the session..."
                      />
                    </div>
                  )}
                  
                  {isMentee && (
                    <div>
                      <label className="block text-sm font-medium text-green-700 mb-1">
                        Mentee's Detailed Feedback
                      </label>
                      <textarea
                        value={newFeedback.mentee_feedback}
                        onChange={(e) => setNewFeedback({ ...newFeedback, mentee_feedback: e.target.value })}
                        className="w-full px-3 py-2 border border-green-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                        rows={3}
                        placeholder="As a mentee, share your experience of the session..."
                      />
                    </div>
                  )}
                </div>
              )}

              {/* Session Completion */}
              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  id="session_completed"
                  checked={newFeedback.session_completed}
                  onChange={(e) => setNewFeedback({ ...newFeedback, session_completed: e.target.checked })}
                  className="rounded text-blue-500 focus:ring-blue-500"
                />
                <label htmlFor="session_completed" className="text-sm font-medium text-gray-700">
                  Mark this session as completed
                </label>
              </div>

              {/* Next Session Goals */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Goals for Next Session
                </label>
                <textarea
                  value={newFeedback.next_session_goals}
                  onChange={(e) => setNewFeedback({ ...newFeedback, next_session_goals: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows={3}
                  placeholder="What should be the focus for the next session?"
                />
              </div>

              <div className="flex justify-end space-x-3 pt-4">
                <button
                  type="button"
                  onClick={() => setShowForm(false)}
                  className="px-4 py-2 text-gray-600 border border-gray-300 rounded-md hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600"
                >
                  Submit Feedback
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default SessionBasedFeedback;