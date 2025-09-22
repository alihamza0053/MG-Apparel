require('dotenv').config();
const supabase = require('./config/supabase');

async function testTables() {
  console.log('Testing database tables...');
  
  try {
    // Test simple queries first
    const { data: sessions, error: sessionsError } = await supabase
      .from('sessions')
      .select('*')
      .limit(1);
    console.log('Sessions table exists:', !sessionsError);
    if (sessionsError) console.log('Sessions error:', sessionsError);
    
    const { data: materials, error: materialsError } = await supabase
      .from('materials')
      .select('*')
      .limit(1);
    console.log('Materials table exists:', !materialsError);
    if (materialsError) console.log('Materials error:', materialsError);
    
    const { data: goals, error: goalsError } = await supabase
      .from('goals')
      .select('*')
      .limit(1);
    console.log('Goals table exists:', !goalsError);
    if (goalsError) console.log('Goals error:', goalsError);
    
    // Test complex join queries
    console.log('\nTesting complex joins...');
    
    // Test sessions join
    const { data: sessionsJoin, error: sessionsJoinError } = await supabase
      .from('sessions')
      .select(`
        id,
        pair_id,
        date,
        pairs:pairs!sessions_pair_id_fkey(
          id,
          mentor:users!pairs_mentor_id_fkey(name),
          mentee:users!pairs_mentee_id_fkey(name)
        )
      `)
      .limit(1);
    console.log('Sessions join works:', !sessionsJoinError);
    if (sessionsJoinError) console.log('Sessions join error:', sessionsJoinError);
    
    // Test materials join
    const { data: materialsJoin, error: materialsJoinError } = await supabase
      .from('materials')
      .select(`
        id,
        pair_id,
        title,
        pairs:pairs!materials_pair_id_fkey(
          id,
          mentor:users!pairs_mentor_id_fkey(name)
        )
      `)
      .limit(1);
    console.log('Materials join works:', !materialsJoinError);
    if (materialsJoinError) console.log('Materials join error:', materialsJoinError);
    
    // Test goals join
    const { data: goalsJoin, error: goalsJoinError } = await supabase
      .from('goals')
      .select(`
        id,
        pair_id,
        title,
        pairs:pairs!goals_pair_id_fkey(
          id,
          mentor:users!pairs_mentor_id_fkey(name)
        )
      `)
      .limit(1);
    console.log('Goals join works:', !goalsJoinError);
    if (goalsJoinError) console.log('Goals join error:', goalsJoinError);
    
  } catch (err) {
    console.error('Test error:', err);
  }
}

testTables();
