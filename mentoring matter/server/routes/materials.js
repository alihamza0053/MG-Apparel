const express = require('express');
const auth = require('../middleware/auth');
const supabase = require('../config/supabase');
const router = express.Router();

// Get materials for user's pairs
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
    const { data: materials, error } = await supabase
      .from('materials')
      .select('*')
      .in('pair_id', pairIds)
      .order('created_at', { ascending: false });

    if (error) throw error;
    res.json(materials || []);
  } catch (err) {
    console.error('Materials fetch error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Create material (mentors only)
router.post('/', auth(['mentor']), async (req, res) => {
  const { pair_id, title, description, url, file_path, type } = req.body;
  try {
    // Verify mentor owns this pair
    const { data: pair, error: pairError } = await supabase
      .from('pairs')
      .select('mentor_id')
      .eq('id', pair_id)
      .single();

    if (pairError || !pair) {
      return res.status(404).json({ message: 'Pair not found' });
    }

    if (pair.mentor_id !== req.user.id) {
      return res.status(403).json({ message: 'Access denied' });
    }
    
    const { data: material, error } = await supabase
      .from('materials')
      .insert([{
        pair_id,
        mentor_id: req.user.id,
        title,
        description,
        url,
        file_path,
        type
      }])
      .select()
      .single();

    if (error) throw error;
    res.json(material);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
