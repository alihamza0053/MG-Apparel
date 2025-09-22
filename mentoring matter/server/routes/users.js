const express = require('express');
const auth = require('../middleware/auth');
const supabase = require('../config/supabase');
const bcrypt = require('bcryptjs');
const router = express.Router();

// Get available mentors and mentees for pairing
router.get('/available', auth(), async (req, res) => {
  try {
    console.log('Fetching available users for organization:', req.user.organization);
    
    const { data: mentors, error: mentorError } = await supabase
      .from('users')
      .select('id, name, email')
      .eq('role', 'mentor')
      .eq('organization', req.user.organization);

    if (mentorError) {
      console.error('Mentor fetch error:', mentorError);
      throw mentorError;
    }

    const { data: mentees, error: menteeError } = await supabase
      .from('users')
      .select('id, name, email')
      .eq('role', 'mentee')
      .eq('organization', req.user.organization);

    if (menteeError) {
      console.error('Mentee fetch error:', menteeError);
      throw menteeError;
    }

    console.log('Found mentors:', mentors?.length || 0);
    console.log('Found mentees:', mentees?.length || 0);
    
    res.json({ mentors: mentors || [], mentees: mentees || [] });
  } catch (err) {
    console.error('Available users error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Get all users (admin only)
router.get('/', auth(['admin']), async (req, res) => {
  try {
    console.log('Fetching all users for organization:', req.user.organization);
    const { data: users, error } = await supabase
      .from('users')
      .select('id, name, email, role, created_at')
      .eq('organization', req.user.organization);

    if (error) {
      console.error('Users fetch error:', error);
      throw error;
    }
    
    console.log('Found users:', users?.length || 0);
    res.json(users || []);
  } catch (err) {
    console.error('Users route error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Create user (admin only)
router.post('/', auth(['admin']), async (req, res) => {
  const { name, email, password, role } = req.body;
  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    
    const { data: newUser, error } = await supabase
      .from('users')
      .insert([{
        name,
        email,
        password: hashedPassword,
        role,
        organization: req.user.organization
      }])
      .select()
      .single();

    if (error) throw error;
    
    // Don't send password back
    const { password: _, ...userResponse } = newUser;
    res.status(201).json(userResponse);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update user (admin only)
router.put('/:id', auth(['admin']), async (req, res) => {
  const { name, email, role } = req.body;
  try {
    const { data: updatedUser, error } = await supabase
      .from('users')
      .update({ name, email, role })
      .eq('id', req.params.id)
      .eq('organization', req.user.organization)
      .select()
      .single();

    if (error) throw error;
    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json(updatedUser);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Delete user (admin only)
router.delete('/:id', auth(['admin']), async (req, res) => {
  try {
    const { error } = await supabase
      .from('users')
      .delete()
      .eq('id', req.params.id)
      .eq('organization', req.user.organization);

    if (error) throw error;
    res.json({ message: 'User deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
