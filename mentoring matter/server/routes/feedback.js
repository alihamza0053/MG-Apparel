const express = require('express');
const auth = require('../middleware/auth');
const supabase = require('../config/supabase');
const router = express.Router();

// Get feedback for user's sessions
router.get('/', auth(), async (req, res) => {
  try {
    let pairQuery = supabase.from('pairs').select('id');
    
    if (req.user.role === 'mentor') {
      pairQuery = pairQuery.eq('mentor_id', req.user.id);
    } else if (req.user.role === 'mentee') {
      pairQuery = pairQuery.eq('mentee_id', req.user.id);
    } else if (req.user.role === 'admin') {
      pairQuery = pairQuery.eq('organization', req.user.organization);
    }
    
    const { data: pairs, error: pairError } = await pairQuery;
    if (pairError) throw pairError;
    
    if (!pairs || pairs.length === 0) {
      return res.json([]);
    }
    
    const pairIds = pairs.map(pair => pair.id);
    
    const { data: sessions, error: sessionError } = await supabase
      .from('sessions')
      .select('id')
      .in('pair_id', pairIds);

    if (sessionError) throw sessionError;
    
    if (!sessions || sessions.length === 0) {
      return res.json([]);
    }
    
    const sessionIds = sessions.map(session => session.id);
    
    const { data: feedback, error } = await supabase
      .from('feedback')
      .select(`
        id,
        session_id,
        user_id,
        rating,
        comments,
        created_at,
        sessions:sessions!feedback_session_id_fkey(
          id,
          date,
          duration,
          pairs:pairs!sessions_pair_id_fkey(
            mentor:users!pairs_mentor_id_fkey(name),
            mentee:users!pairs_mentee_id_fkey(name)
          )
        ),
        users:users!feedback_user_id_fkey(name, role)
      `)
      .in('session_id', sessionIds)
      .order('created_at', { ascending: false });

    if (error) throw error;
    res.json(feedback || []);
  } catch (err) {
    console.error('Feedback fetch error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Create feedback
router.post('/', auth(['mentor', 'mentee']), async (req, res) => {
  const { session_id, rating, comments } = req.body;
  try {
    // Verify user belongs to this session's pair
    const { data: session, error: sessionError } = await supabase
      .from('sessions')
      .select(`
        id,
        pair_id,
        pairs:pair_id(mentor_id, mentee_id)
      `)
      .eq('id', session_id)
      .single();

    if (sessionError || !session) {
      return res.status(404).json({ message: 'Session not found' });
    }

    if (session.pairs.mentor_id !== req.user.id && session.pairs.mentee_id !== req.user.id) {
      return res.status(403).json({ message: 'Access denied' });
    }
    
    const { data: feedback, error } = await supabase
      .from('feedback')
      .insert([{
        session_id,
        user_id: req.user.id,
        rating,
        comments
      }])
      .select()
      .single();

    if (error) throw error;
    res.json(feedback);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
