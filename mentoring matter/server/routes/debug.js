// Add debugging routes for troubleshooting
const express = require('express');
const supabase = require('../config/supabase');
const router = express.Router();

// Debug all tables
router.get('/debug-all', async (req, res) => {
  try {
    console.log('=== DEBUG ALL TABLES ===');
    
    const results = {};
    
    // Check users
    const { data: users, error: usersError } = await supabase.from('users').select('*');
    results.users = { count: users?.length || 0, data: users, error: usersError };
    
    // Check pairs
    const { data: pairs, error: pairsError } = await supabase.from('pairs').select('*');
    results.pairs = { count: pairs?.length || 0, data: pairs, error: pairsError };
    
    // Check sessions
    const { data: sessions, error: sessionsError } = await supabase.from('sessions').select('*');
    results.sessions = { count: sessions?.length || 0, data: sessions, error: sessionsError };
    
    // Check materials
    const { data: materials, error: materialsError } = await supabase.from('materials').select('*');
    results.materials = { count: materials?.length || 0, data: materials, error: materialsError };
    
    // Check goals
    const { data: goals, error: goalsError } = await supabase.from('goals').select('*');
    results.goals = { count: goals?.length || 0, data: goals, error: goalsError };
    
    // Check feedback
    const { data: feedback, error: feedbackError } = await supabase.from('feedback').select('*');
    results.feedback = { count: feedback?.length || 0, data: feedback, error: feedbackError };
    
    console.log('Debug results:', results);
    res.json(results);
  } catch (err) {
    console.error('Debug error:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
