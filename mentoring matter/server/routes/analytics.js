const express = require('express');
const auth = require('../middleware/auth');
const supabase = require('../config/supabase');
const router = express.Router();

// Get analytics data (admin only)
router.get('/', auth(['admin']), async (req, res) => {
  try {
    const org = req.user.organization;
    
    // Active pairs count
    const { count: activePairs, error: pairsError } = await supabase
      .from('pairs')
      .select('*', { count: 'exact' })
      .eq('organization', org)
      .eq('status', 'active');

    if (pairsError) throw pairsError;
    
    // Get all pairs for this organization
    const { data: pairs, error: allPairsError } = await supabase
      .from('pairs')
      .select('id')
      .eq('organization', org);

    if (allPairsError) throw allPairsError;
    
    const pairIds = pairs.map(pair => pair.id);
    
    // Total sessions count
    const { count: totalSessions, error: sessionsError } = await supabase
      .from('sessions')
      .select('*', { count: 'exact' })
      .in('pair_id', pairIds);

    if (sessionsError) throw sessionsError;
    
    // Get all sessions for feedback calculation
    const { data: sessions, error: allSessionsError } = await supabase
      .from('sessions')
      .select('id')
      .in('pair_id', pairIds);

    if (allSessionsError) throw allSessionsError;
    
    const sessionIds = sessions.map(session => session.id);
    
    // Average rating calculation
    const { data: feedbacks, error: feedbackError } = await supabase
      .from('feedback')
      .select('rating')
      .in('session_id', sessionIds);

    if (feedbackError) throw feedbackError;
    
    const avgRating = feedbacks.length > 0 
      ? feedbacks.reduce((sum, f) => sum + f.rating, 0) / feedbacks.length 
      : 0;
    
    // Goal progress
    const { data: goals, error: goalsError } = await supabase
      .from('goals')
      .select('status')
      .in('pair_id', pairIds);

    if (goalsError) throw goalsError;
    
    const goalStats = {
      'Not Started': goals.filter(g => g.status === 'not_started').length,
      'In Progress': goals.filter(g => g.status === 'in_progress').length,
      'Completed': goals.filter(g => g.status === 'completed').length
    };
    
    // Users by role
    const { data: users, error: usersError } = await supabase
      .from('users')
      .select('role')
      .eq('organization', org);

    if (usersError) throw usersError;
    
    const userStats = {
      admin: users.filter(u => u.role === 'admin').length,
      mentor: users.filter(u => u.role === 'mentor').length,
      mentee: users.filter(u => u.role === 'mentee').length
    };
    
    res.json({
      activePairs: activePairs || 0,
      totalSessions: totalSessions || 0,
      avgRating: Math.round(avgRating * 10) / 10,
      goalStats,
      userStats
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Export CSV data (admin only)
router.get('/export', auth(['admin']), async (req, res) => {
  try {
    const org = req.user.organization;
    const { data: pairs, error } = await supabase
      .from('pairs')
      .select(`
        id,
        mentor:mentor_id(name, email),
        mentee:mentee_id(name, email)
      `)
      .eq('organization', org);

    if (error) throw error;
    
    let csv = 'Mentor Name,Mentor Email,Mentee Name,Mentee Email\n';
    pairs.forEach(pair => {
      csv += `${pair.mentor?.name || 'N/A'},${pair.mentor?.email || 'N/A'},${pair.mentee?.name || 'N/A'},${pair.mentee?.email || 'N/A'}\n`;
    });
    
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename=mentoring-pairs.csv');
    res.send(csv);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
