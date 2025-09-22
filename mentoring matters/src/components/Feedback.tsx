import React, { useState, useEffect, useCallback } from 'react';
import { supabase } from '../supabaseClient';
import { useAuth } from '../AuthContext';
import { Star, MessageCircle, Calendar, User, Search, Plus } from 'lucide-react';
import { format } from 'date-fns';

interface Feedback {
  id: string;
  created_at: string;
  session_date?: string;
  rating: number;
  comments: string;
  mentor_id?: string;
  mentee_id?: string;
  pair_id?: string;
  mentor?: {
    full_name: string;
    avatar_url?: string;
  };
  mentee?: {
    full_name: string;
    avatar_url?: string;
  };
}

interface NewFeedback {
  session_date: string;
  rating: number;
  comments: string;
  pair_id: string;
}

const Feedback: React.FC = () => {
  const { user } = useAuth();
  const [feedback, setFeedback] = useState<Feedback[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [newFeedback, setNewFeedback] = useState<NewFeedback>({
    session_date: '',
    rating: 5,
    comments: '',
    pair_id: ''
  });
  const [pairs, setPairs] = useState<any[]>([]);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      
      // First get all profiles for lookup
      const { data: profilesForLookup, error: profileError } = await supabase
        .from('profiles')
        .select('id, full_name, avatar_url, role');

      console.log('Profiles for feedback lookup:', profilesForLookup, 'Error:', profileError);

      // Create a lookup map
      const profileMap = new Map();
      if (profilesForLookup) {
        profilesForLookup.forEach(profile => {
          profileMap.set(profile.id, profile);
        });
        console.log('Created profile map with', profileMap.size, 'profiles');
        console.log('Profile map entries:', Array.from(profileMap.entries()));
      }

      // Get feedback data with simple query
      const { data, error } = await supabase
        .from('feedback')
        .select(`
          id,
          created_at,
          session_date,
          rating,
          comments,
          mentor_id,
          mentee_id,
          pair_id
        `)
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Error fetching feedback:', error);
        throw error;
      }
      
      console.log('Fetched feedback data:', data);
      
      // Process feedback with profile lookup
      if (data && data.length > 0) {
        const feedbackWithProfiles = data.map((feedback: any) => {
          console.log('Processing feedback:', feedback);
          
          let mentor = null;
          let mentee = null;

          if (feedback.mentor_id && feedback.mentee_id) {
            mentor = profileMap.get(feedback.mentor_id);
            mentee = profileMap.get(feedback.mentee_id);
            
            console.log(`Feedback ${feedback.id}:`);
            console.log('- Mentor ID:', feedback.mentor_id, '→ Profile:', mentor);
            console.log('- Mentee ID:', feedback.mentee_id, '→ Profile:', mentee);
            console.log('- Profile map has mentor:', profileMap.has(feedback.mentor_id));
            console.log('- Profile map has mentee:', profileMap.has(feedback.mentee_id));
            
            // Debug: show all map keys
            console.log('- All profile map keys:', Array.from(profileMap.keys()));
          } else {
            console.log(`Feedback ${feedback.id} missing mentor_id or mentee_id:`, {
              mentor_id: feedback.mentor_id,
              mentee_id: feedback.mentee_id,
              pair_id: feedback.pair_id
            });
          }

          const result = {
            ...feedback,
            mentor: mentor || { full_name: 'Unknown Mentor', avatar_url: null },
            mentee: mentee || { full_name: 'Unknown Mentee', avatar_url: null }
          };
          
          console.log('Final feedback result:', result);
          return result;
        });

        console.log('Final feedback with profiles:', feedbackWithProfiles);
        setFeedback(feedbackWithProfiles);
      } else {
        setFeedback([]);
      }
      
    } catch (error) {
      console.error('Error in fetchData:', error);
      setFeedback([]);
    } finally {
      setLoading(false);
    }
  }, []); // No dependencies needed since this function doesn't use any state

  const fetchPairs = useCallback(async () => {
    try {
      console.log('Fetching pairs for user:', user?.id, 'role:', user?.role);
      
      // First, let's check if we have any pairs at all
      const { data: allPairs, error: allPairsError } = await supabase
        .from('mentoring_pairs')
        .select('*');
      
      console.log('All pairs in database:', allPairs, 'Error:', allPairsError);
      
      // Also check all profiles
      const { data: allProfiles, error: profilesError } = await supabase
        .from('profiles')
        .select('id, full_name, role');
      
      console.log('All profiles in database:', allProfiles, 'Error:', profilesError);
      
      // Let's also check the specific profiles we're looking for
      if (allProfiles && allProfiles.length > 0) {
        console.log('Profile details:');
        allProfiles.forEach(profile => {
          console.log(`- ${profile.full_name} (${profile.role}) ID: ${profile.id}`);
        });
      }

      // Let's first get all profiles as a lookup table
      const { data: allProfilesForLookup, error: profileLookupError } = await supabase
        .from('profiles')
        .select('id, full_name, role');

      console.log('Profiles for lookup:', allProfilesForLookup, 'Error:', profileLookupError);

      // Create a lookup map for faster access
      const profileMap = new Map();
      if (allProfilesForLookup) {
        allProfilesForLookup.forEach(profile => {
          profileMap.set(profile.id, profile);
        });
      }

      console.log('Profile lookup map:', profileMap);

      // Now get pairs using simple query (no joins)
      let simpleQuery = supabase
        .from('mentoring_pairs')
        .select(`
          id,
          mentor_id,
          mentee_id,
          status
        `)
        .eq('status', 'active');

      // Filter based on user role
      if (user?.role === 'mentor') {
        simpleQuery = simpleQuery.eq('mentor_id', user.id);
      } else if (user?.role === 'mentee') {
        simpleQuery = simpleQuery.eq('mentee_id', user.id);
      }

      const { data: simplePairsData, error: simplePairsError } = await simpleQuery;
      
      console.log('Simple pairs data:', simplePairsData, 'Error:', simplePairsError);

      if (!simplePairsError && simplePairsData) {
        const pairsWithNames = simplePairsData.map((pair: any) => {
          const mentor = profileMap.get(pair.mentor_id);
          const mentee = profileMap.get(pair.mentee_id);
          
          console.log(`Pair ${pair.id}:`);
          console.log('- Mentor ID:', pair.mentor_id, '→ Profile:', mentor);
          console.log('- Mentee ID:', pair.mentee_id, '→ Profile:', mentee);
          
          return {
            ...pair,
            mentor_name: mentor?.full_name || `Mentor (${pair.mentor_id})`,
            mentee_name: mentee?.full_name || `Mentee (${pair.mentee_id})`
          };
        });

        console.log('Final pairs with names:', pairsWithNames);
        setPairs(pairsWithNames);
        return;
      }

      console.log('Simple query failed, trying original approach...');
      
      // Fallback: separate queries
      let fallbackQuery = supabase
        .from('mentoring_pairs')
        .select(`
          id,
          mentor_id,
          mentee_id,
          status
        `)
        .eq('status', 'active');

      // Filter based on user role
      if (user?.role === 'mentor') {
        fallbackQuery = fallbackQuery.eq('mentor_id', user.id);
      } else if (user?.role === 'mentee') {
        fallbackQuery = fallbackQuery.eq('mentee_id', user.id);
      }

      const { data: pairsData, error: pairsError } = await fallbackQuery;
      if (pairsError) {
        console.error('Error fetching pairs:', pairsError);
        throw pairsError;
      }

      console.log('Raw pairs data:', pairsData);

      // Now fetch the mentor and mentee profiles for each pair
      if (pairsData && pairsData.length > 0) {
        const pairsWithProfiles = await Promise.all(
          pairsData.map(async (pair: any) => {
            console.log('Processing pair:', pair);
            
            const [mentorResult, menteeResult] = await Promise.all([
              supabase
                .from('profiles')
                .select('id, full_name')
                .eq('id', pair.mentor_id)
                .single(),
              supabase
                .from('profiles')
                .select('id, full_name')
                .eq('id', pair.mentee_id)
                .single()
            ]);

            console.log('Mentor profile result:', mentorResult);
            console.log('Mentee profile result:', menteeResult);

            return {
              ...pair,
              mentor_name: mentorResult.data?.full_name || `Mentor (${pair.mentor_id})`,
              mentee_name: menteeResult.data?.full_name || `Mentee (${pair.mentee_id})`
            };
          })
        );

        console.log('Pairs with profiles:', pairsWithProfiles);
        setPairs(pairsWithProfiles);
      } else {
        console.log('No pairs found or empty result');
        setPairs([]);
      }
    } catch (error) {
      console.error('Error fetching pairs:', error);
      setPairs([]);
    }
  }, [user?.id, user?.role]); // Depend on user ID and role

  useEffect(() => {
    if (user?.id) {
      fetchData();
      fetchPairs();
    }
  }, [user?.id, fetchData, fetchPairs]); // Include the memoized functions

  // Admin function to clear old feedback records (debugging)
  const clearOldFeedback = async () => {
    try {
      const { data, error } = await supabase
        .from('feedback')
        .delete()
        .is('mentor_id', null);
      
      if (error) {
        console.error('Error clearing old feedback:', error);
        alert('Error clearing old feedback: ' + error.message);
      } else {
        console.log('Cleared old feedback records:', data);
        alert('Cleared old feedback records successfully!');
        fetchData(); // Refresh the data
      }
    } catch (error) {
      console.error('Error in clearOldFeedback:', error);
    }
  };

  const createTestPair = async () => {
    if (!user || user.role !== 'admin') {
      alert('Only admins can create test pairs');
      return;
    }

    try {
      // Get all profiles to create a test pair
      const { data: profiles, error: profilesError } = await supabase
        .from('profiles')
        .select('id, full_name, role');

      if (profilesError) {
        console.error('Error fetching profiles:', profilesError);
        alert('Error fetching profiles: ' + profilesError.message);
        return;
      }

      console.log('Available profiles:', profiles);

      const mentors = profiles?.filter(p => p.role === 'mentor') || [];
      const mentees = profiles?.filter(p => p.role === 'mentee') || [];

      if (mentors.length === 0 || mentees.length === 0) {
        alert(`Need both mentors (${mentors.length}) and mentees (${mentees.length}) to create a pair`);
        return;
      }

      // Create a test pair with first mentor and first mentee
      const { data: newPair, error: pairError } = await supabase
        .from('mentoring_pairs')
        .insert([{
          mentor_id: mentors[0].id,
          mentee_id: mentees[0].id,
          status: 'active'
        }])
        .select();

      if (pairError) {
        console.error('Error creating pair:', pairError);
        alert('Error creating pair: ' + pairError.message);
        return;
      }

      console.log('Created test pair:', newPair);
      alert(`Test pair created: ${mentors[0].full_name} → ${mentees[0].full_name}`);
      
      // Refresh pairs
      fetchPairs();
    } catch (error) {
      console.error('Error in createTestPair:', error);
      alert('Error creating test pair. Check console for details.');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      console.log('Submitting feedback:', newFeedback);
      
      if (!newFeedback.session_date || !newFeedback.comments || !newFeedback.pair_id) {
        alert('Please fill in all required fields: session date, comments, and mentor-mentee pair');
        return;
      }

      // Get mentor and mentee IDs from the selected pair
      const selectedPair = pairs.find(pair => pair.id === newFeedback.pair_id);
      if (!selectedPair) {
        alert('Please select a valid mentor-mentee pair');
        return;
      }

      console.log('Selected pair for feedback:', selectedPair);
      console.log('About to insert feedback with:', {
        session_date: newFeedback.session_date,
        rating: newFeedback.rating,
        comments: newFeedback.comments,
        mentor_id: selectedPair.mentor_id,
        mentee_id: selectedPair.mentee_id,
        pair_id: newFeedback.pair_id
      });

      const { data, error } = await supabase
        .from('feedback')
        .insert([{
          session_date: newFeedback.session_date,
          rating: newFeedback.rating,
          comments: newFeedback.comments,
          mentor_id: selectedPair.mentor_id,
          mentee_id: selectedPair.mentee_id,
          pair_id: newFeedback.pair_id
        }])
        .select();

      if (error) {
        console.error('Supabase error:', error);
        alert('Error submitting feedback: ' + error.message);
        return;
      }

      console.log('Feedback added successfully:', data);
      alert('Feedback submitted successfully!');
      
      setNewFeedback({
        session_date: '',
        rating: 5,
        comments: '',
        pair_id: ''
      });
      setShowForm(false);
      fetchData();
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

  const filteredFeedback = feedback.filter(item =>
    item.comments.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold text-gray-800">Session Feedback</h1>
        <div className="flex space-x-2">
          {user?.role === 'admin' && (
            <>
              <button
                onClick={createTestPair}
                className="bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded-lg flex items-center space-x-2"
              >
                <Plus className="w-4 h-4" />
                <span>Create Test Pair</span>
              </button>
              <button
                onClick={clearOldFeedback}
                className="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded-lg flex items-center space-x-2"
              >
                <span>Clear Old Feedback</span>
              </button>
            </>
          )}
          <button
            onClick={() => setShowForm(!showForm)}
            className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-lg flex items-center space-x-2"
          >
            <Plus className="w-4 h-4" />
            <span>Add Feedback</span>
          </button>
        </div>
      </div>

      {/* Search Bar */}
      <div className="relative mb-6">
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
        <input
          type="text"
          placeholder="Search feedback..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
        />
      </div>

      {/* Add Feedback Form */}
      {showForm && (
        <div className="bg-white p-6 rounded-lg shadow-lg mb-6 border">
          <h2 className="text-xl font-semibold mb-4">Add New Feedback</h2>
          
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Session Date
              </label>
              <input
                type="date"
                required
                value={newFeedback.session_date}
                onChange={(e) => setNewFeedback({ ...newFeedback, session_date: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Mentor-Mentee Pair {pairs.length > 0 && `(${pairs.length} available)`}
              </label>
              <select
                required
                value={newFeedback.pair_id}
                onChange={(e) => setNewFeedback({ ...newFeedback, pair_id: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              >
                <option value="">
                  {pairs.length === 0 ? 'No mentor-mentee pairs available' : 'Select a mentor-mentee pair...'}
                </option>
                {pairs.map((pair) => (
                  <option key={pair.id} value={pair.id}>
                    {pair.mentor_name} → {pair.mentee_name}
                  </option>
                ))}
              </select>
              {pairs.length === 0 && (
                <p className="text-sm text-gray-500 mt-1">
                  No active mentor-mentee pairs found. Please create pairs in the Mentoring section first.
                </p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Rating
              </label>
              <select
                value={newFeedback.rating}
                onChange={(e) => setNewFeedback({ ...newFeedback, rating: parseInt(e.target.value) })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              >
                <option value={1}>1 Star - Poor</option>
                <option value={2}>2 Stars - Fair</option>
                <option value={3}>3 Stars - Good</option>
                <option value={4}>4 Stars - Very Good</option>
                <option value={5}>5 Stars - Excellent</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Comments
              </label>
              <textarea
                required
                rows={4}
                value={newFeedback.comments}
                onChange={(e) => setNewFeedback({ ...newFeedback, comments: e.target.value })}
                placeholder="Share your feedback about the session..."
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div className="flex space-x-4">
              <button
                type="submit"
                className="bg-blue-500 hover:bg-blue-600 text-white px-6 py-2 rounded-lg"
              >
                Submit Feedback
              </button>
              <button
                type="button"
                onClick={() => setShowForm(false)}
                className="bg-gray-500 hover:bg-gray-600 text-white px-6 py-2 rounded-lg"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Feedback List */}
      <div className="space-y-4">
        {filteredFeedback.length === 0 ? (
          <div className="text-center py-8">
            <MessageCircle className="mx-auto h-12 w-12 text-gray-400 mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No feedback found</h3>
            <p className="text-gray-500">
              {searchTerm ? 'Try adjusting your search criteria.' : 'Be the first to add feedback!'}
            </p>
          </div>
        ) : (
          filteredFeedback.map((item) => (
            <div key={item.id} className="bg-white p-6 rounded-lg shadow-lg border">
              <div className="flex justify-between items-start mb-4">
                <div className="flex items-center space-x-3">
                  <User className="w-10 h-10 text-gray-400 bg-gray-100 rounded-full p-2" />
                  <div>
                    <h3 className="font-semibold text-gray-800">
                      {item.mentor?.full_name || 'Unknown'} → {item.mentee?.full_name || 'Unknown'}
                    </h3>
                    <div className="flex items-center space-x-4 text-sm text-gray-600">
                      <div className="flex items-center space-x-1">
                        <Calendar className="w-4 h-4" />
                        <span>
                          Session: {item.session_date ? format(new Date(item.session_date), 'MMM d, yyyy') : 'N/A'}
                        </span>
                      </div>
                      <div className="flex items-center space-x-1">
                        <Calendar className="w-4 h-4" />
                        <span>
                          Added: {format(new Date(item.created_at), 'MMM d, yyyy')}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              
              <div className="flex items-center space-x-2 mb-3">
                {renderStars(item.rating)}
                <span className="text-sm text-gray-600">({item.rating}/5)</span>
              </div>
              
              <p className="text-gray-700 mb-3">{item.comments}</p>
              
              <div className="text-xs text-gray-500 border-t pt-3">
                Feedback ID: {item.id}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default Feedback;