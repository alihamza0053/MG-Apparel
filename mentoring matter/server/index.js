
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const supabase = require('./config/supabase');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const pairRoutes = require('./routes/pairs');
const goalRoutes = require('./routes/goals');
const sessionRoutes = require('./routes/sessions');
const feedbackRoutes = require('./routes/feedback');
const materialRoutes = require('./routes/materials');
const analyticsRoutes = require('./routes/analytics');
const debugRoutes = require('./routes/debug');
const app = express();

// Test Supabase connection
const testSupabaseConnection = async () => {
  try {
    const { data, error } = await supabase.from('users').select('count', { count: 'exact' });
    if (error) {
      console.log('Supabase connection test failed:', error.message);
      console.log('Please ensure your Supabase tables are set up correctly.');
    } else {
      console.log('Supabase connected successfully');
    }
  } catch (err) {
    console.log('Supabase connection error:', err.message);
  }
};

testSupabaseConnection();

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ message: 'Mentoring Matters backend is running with Supabase', timestamp: new Date() });
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'API is working with Supabase' });
});

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/pairs', pairRoutes);
app.use('/api/goals', goalRoutes);
app.use('/api/sessions', sessionRoutes);
app.use('/api/feedback', feedbackRoutes);
app.use('/api/materials', materialRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/debug', debugRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT} with Supabase`);
});
