require('dotenv').config();
const supabase = require('./config/supabase');

async function checkTableStructure() {
  console.log('Checking table structures...');
  
  try {
    // Get sample data to see actual column names
    const { data: materials, error: materialsError } = await supabase
      .from('materials')
      .select('*')
      .limit(1);
    console.log('Materials data:', materials);
    if (materialsError) console.log('Materials error:', materialsError);
    
    const { data: sessions, error: sessionsError } = await supabase
      .from('sessions')
      .select('*')
      .limit(1);
    console.log('Sessions data:', sessions);
    if (sessionsError) console.log('Sessions error:', sessionsError);
    
    const { data: goals, error: goalsError } = await supabase
      .from('goals')
      .select('*')
      .limit(1);
    console.log('Goals data:', goals);
    if (goalsError) console.log('Goals error:', goalsError);
    
  } catch (err) {
    console.error('Check error:', err);
  }
}

checkTableStructure();
