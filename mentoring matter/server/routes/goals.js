const express = require('express');
const auth = require('../middleware/auth');
const supabase = require('../config/supabase');
const router = express.Router();

// Get goals for user's pairs
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
    
    // Simplified query without complex joins
    const { data: goals, error } = await supabase
      .from('goals')
      .select('*')
      .in('pair_id', pairIds)
      .order('created_at', { ascending: false });

    if (error) throw error;
    res.json(goals || []);
  } catch (err) {
    console.error('Goals fetch error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Create goal
router.post('/', auth(['mentor', 'mentee']), async (req, res) => {
  const { pair_id, title, description } = req.body;
  try {
    // Verify user belongs to this pair
    const { data: pair, error: pairError } = await supabase
      .from('pairs')
      .select('mentor_id, mentee_id')
      .eq('id', pair_id)
      .single();

    if (pairError || !pair) {
      return res.status(404).json({ message: 'Pair not found' });
    }

    if (pair.mentor_id !== req.user.id && pair.mentee_id !== req.user.id) {
      return res.status(403).json({ message: 'Access denied' });
    }
    
    const { data: goal, error } = await supabase
      .from('goals')
      .insert([{
        pair_id,
        title,
        description
      }])
      .select()
      .single();

    if (error) throw error;
    res.json(goal);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update goal status
router.put('/:id', auth(['mentor', 'mentee']), async (req, res) => {
  const { status } = req.body;
  try {
    // First get the goal with its pair info
    const { data: goal, error: goalError } = await supabase
      .from('goals')
      .select(`
        id,
        pair_id,
        title,
        description,
        status,
        pairs:pair_id(mentor_id, mentee_id)
      `)
      .eq('id', req.params.id)
      .single();

    if (goalError || !goal) {
      return res.status(404).json({ message: 'Goal not found' });
    }
    
    // Verify user belongs to this pair
    if (goal.pairs.mentor_id !== req.user.id && goal.pairs.mentee_id !== req.user.id) {
      return res.status(403).json({ message: 'Access denied' });
    }
    
    const { data: updatedGoal, error } = await supabase
      .from('goals')
      .update({ status })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;
    res.json(updatedGoal);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
