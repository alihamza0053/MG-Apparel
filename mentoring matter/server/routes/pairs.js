const express = require('express');
const auth = require('../middleware/auth');
const supabase = require('../config/supabase');
const router = express.Router();

// Simple debugging endpoint that shows everything
router.get('/debug-simple', async (req, res) => {
  try {
    console.log('=== SIMPLE DEBUG ===');
    
    // Get ALL users (no auth needed for debugging)
    const { data: allUsers, error: usersError } = await supabase
      .from('users')
      .select('*');
    
    if (usersError) {
      console.error('Users error:', usersError);
    } else {
      console.log('All users in database:', allUsers);
    }
    
    // Get ALL pairs (no auth needed for debugging)
    const { data: allPairs, error: pairsError } = await supabase
      .from('pairs')
      .select('*');
    
    if (pairsError) {
      console.error('Pairs error:', pairsError);
    } else {
      console.log('All pairs in database:', allPairs);
    }
    
    res.json({
      users: allUsers || [],
      pairs: allPairs || [],
      usersError,
      pairsError
    });
  } catch (err) {
    console.error('Simple debug error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Create pair automatically using actual user IDs
router.get('/create-test-pair', async (req, res) => {
  try {
    console.log('=== CREATING TEST PAIR ===');
    
    // First get the mentor and mentee IDs
    const { data: mentor } = await supabase
      .from('users')
      .select('id, name, email')
      .eq('email', 'ali@gmail.com')
      .eq('role', 'mentor')
      .single();
      
    const { data: mentee } = await supabase
      .from('users')
      .select('id, name, email')
      .eq('email', 'hamza@gmail.com')
      .eq('role', 'mentee')
      .single();
    
    if (!mentor || !mentee) {
      return res.status(404).json({ 
        error: 'Mentor or mentee not found',
        mentor,
        mentee
      });
    }
    
    console.log('Found mentor:', mentor);
    console.log('Found mentee:', mentee);
    
    // Create the pair
    const { data: pair, error: pairError } = await supabase
      .from('pairs')
      .insert([{
        mentor_id: mentor.id,
        mentee_id: mentee.id,
        organization: 'MG Apparel',
        start_date: new Date().toISOString().split('T')[0],
        end_date: new Date(Date.now() + 6 * 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        status: 'active'
      }])
      .select()
      .single();
    
    if (pairError) {
      console.error('Pair creation error:', pairError);
      return res.status(500).json({ error: pairError.message });
    }
    
    console.log('Created pair:', pair);
    
    res.json({
      success: true,
      message: 'Test pair created successfully!',
      mentor,
      mentee,
      pair
    });
  } catch (err) {
    console.error('Create test pair error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Test mentor pairs specifically
router.get('/test-mentor', async (req, res) => {
  try {
    console.log('=== TESTING MENTOR PAIRS ===');
    
    // Test with the mentor ID we know exists
    const mentorId = '6d381775-69e7-40a5-aa5f-fddbf8c010d5'; // ali@gmail.com
    
    console.log('Looking for pairs with mentor_id:', mentorId);
    
    const { data: pairs, error } = await supabase
      .from('pairs')
      .select('*')
      .eq('mentor_id', mentorId);
    
    if (error) {
      console.error('Query error:', error);
      return res.status(500).json({ error: error.message });
    }
    
    console.log('Found pairs for mentor:', pairs);
    
    res.json({
      mentorId,
      pairsFound: pairs?.length || 0,
      pairs: pairs || []
    });
  } catch (err) {
    console.error('Test mentor error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Get pairs
router.get('/', auth(), async (req, res) => {
  try {
    console.log('=== PAIRS REQUEST ===');
    console.log('User ID:', req.user.id);
    console.log('User role:', req.user.role);
    console.log('User organization:', req.user.organization);
    
    let query = supabase.from('pairs').select(`
      id,
      mentor_id,
      mentee_id,
      status,
      start_date,
      end_date,
      created_at,
      organization
    `);
    
    if (req.user.role === 'admin') {
      console.log('Admin query: filtering by organization');
      query = query.eq('organization', req.user.organization);
    } else if (req.user.role === 'mentor') {
      console.log('Mentor query: filtering by mentor_id =', req.user.id);
      query = query.eq('mentor_id', req.user.id);
    } else if (req.user.role === 'mentee') {
      console.log('Mentee query: filtering by mentee_id =', req.user.id);
      query = query.eq('mentee_id', req.user.id);
    }
    
    const { data: pairs, error } = await query;
    if (error) {
      console.error('Pairs query error:', error);
      throw error;
    }
    
    console.log('Raw pairs found:', pairs?.length || 0);
    console.log('Pairs data:', JSON.stringify(pairs, null, 2));
    
    // Fetch mentor and mentee details separately
    if (pairs && pairs.length > 0) {
      for (let pair of pairs) {
        console.log('Fetching details for pair:', pair.id);
        console.log('Mentor ID:', pair.mentor_id);
        console.log('Mentee ID:', pair.mentee_id);
        
        // Fetch mentor details
        const { data: mentor } = await supabase
          .from('users')
          .select('id, name, email')
          .eq('id', pair.mentor_id)
          .single();
        
        // Fetch mentee details
        const { data: mentee } = await supabase
          .from('users')
          .select('id, name, email')
          .eq('id', pair.mentee_id)
          .single();
        
        pair.mentor = mentor;
        pair.mentee = mentee;
        console.log('Added mentor:', mentor?.name);
        console.log('Added mentee:', mentee?.name);
      }
    }
    if (error) {
      console.error('Pairs query error:', error);
      throw error;
    }
    
    // If no pairs exist for mentor/mentee, return empty array
    res.json(pairs || []);
  } catch (err) {
    console.error('Pairs fetch error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Create pair (admin only)
router.post('/', auth(['admin']), async (req, res) => {
  const { mentor_id, mentee_id, start_date, end_date } = req.body;
  try {
    const { data: pair, error } = await supabase
      .from('pairs')
      .insert([{
        mentor_id,
        mentee_id,
        start_date,
        end_date,
        organization: req.user.organization
      }])
      .select()
      .single();

    if (error) throw error;
    res.json(pair);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update pair (admin only)
router.put('/:id', auth(['admin']), async (req, res) => {
  try {
    const { data: pair, error } = await supabase
      .from('pairs')
      .update(req.body)
      .eq('id', req.params.id)
      .select(`
        id,
        mentor_id,
        mentee_id,
        status,
        start_date,
        end_date,
        organization
      `)
      .single();

    if (error) throw error;
    if (!pair) {
      return res.status(404).json({ message: 'Pair not found' });
    }
    
    // Fetch mentor and mentee details
    const { data: mentor } = await supabase
      .from('users')
      .select('id, name, email')
      .eq('id', pair.mentor_id)
      .single();
    
    const { data: mentee } = await supabase
      .from('users')
      .select('id, name, email')
      .eq('id', pair.mentee_id)
      .single();
    
    pair.mentor = mentor;
    pair.mentee = mentee;

    if (error) throw error;
    res.json(pair);
  } catch (err) {
    console.error('Pair update error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Delete pair (admin only)
router.delete('/:id', auth(['admin']), async (req, res) => {
  try {
    const { error } = await supabase
      .from('pairs')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;
    res.json({ message: 'Pair deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
