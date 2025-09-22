import React, { useState, useEffect } from 'react';
import { supabase } from '../supabaseClient';
import { useAuth } from '../AuthContext';
import { Star, MessageCircle, Calendar, User, Search, Plus } from 'lucide-react';
import { format } from 'date-fns';

interface Feedback {
  id: string;
  created_at: string;
  rating: number;
  comments: string;
}

interface NewFeedback {
  rating: number;
  comments: string;
}

const Feedback: React.FC = () => {
  const { user } = useAuth();
  const [feedback, setFeedback] = useState<Feedback[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [newFeedback, setNewFeedback] = useState<NewFeedback>({
    rating: 5,
    comments: ''
  });

  const fetchData = async () => {
    try {
      setLoading(true);
      
      const { data, error } = await supabase
        .from('feedback')
        .select('id, created_at, rating, comments')
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Error fetching feedback:', error);
        throw error;
      }
      
      console.log('Fetched feedback data:', data);
      setFeedback(data || []);
      
    } catch (error) {
      console.error('Error in fetchData:', error);
      setFeedback([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [user]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      console.log('Submitting feedback:', newFeedback);
      
      if (!newFeedback.comments || newFeedback.rating === 0) {
        alert('Please provide a rating and comments');
        return;
      }

      const { data, error } = await supabase
        .from('feedback')
        .insert([{
          rating: newFeedback.rating,
          comments: newFeedback.comments
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
        rating: 5,
        comments: ''
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
        <button
          onClick={() => setShowForm(!showForm)}
          className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-lg flex items-center space-x-2"
        >
          <Plus className="w-4 h-4" />
          <span>Add Feedback</span>
        </button>
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
                <div className="flex items-center space-x-2">
                  <User className="w-8 h-8 text-gray-400 bg-gray-100 rounded-full p-1" />
                  <div>
                    <h3 className="font-semibold text-gray-800">Session Feedback</h3>
                    <div className="flex items-center space-x-2">
                      <Calendar className="w-4 h-4 text-gray-400" />
                      <span className="text-sm text-gray-600">
                        {format(new Date(item.created_at), 'MMM d, yyyy')}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
              
              <div className="flex items-center space-x-2 mb-3">
                {renderStars(item.rating)}
                <span className="text-sm text-gray-600">({item.rating}/5)</span>
              </div>
              
              <p className="text-gray-700 mb-3">{item.comments}</p>
              
              <div className="text-xs text-gray-500">
                Added on {format(new Date(item.created_at), 'MMM d, yyyy')}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default Feedback;