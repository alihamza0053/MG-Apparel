const bcrypt = require('bcryptjs');

async function testPassword() {
  const password = 'hamza123';
  const storedHash = '$2a$10$rOvRoi24Kmy7.xKB7V4bU.Vy8GQMK6HHq6gTNyOlpBfQHpf2f2xiq';
  
  console.log('Testing password:', password);
  console.log('Stored hash:', storedHash);
  
  const isValid = await bcrypt.compare(password, storedHash);
  console.log('Password is valid:', isValid);
  
  // Generate a new hash to be sure
  const newHash = await bcrypt.hash(password, 10);
  console.log('New hash:', newHash);
  
  const isNewValid = await bcrypt.compare(password, newHash);
  console.log('New hash is valid:', isNewValid);
}

testPassword().catch(console.error);
