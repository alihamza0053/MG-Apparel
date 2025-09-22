const axios = require('axios');

async function testLogin() {
  try {
    console.log('Testing login API...');
    
    const response = await axios.post('http://localhost:5000/api/auth/login', {
      email: 'alihamza@gmail.com',
      password: 'hamza123'
    });
    
    console.log('Login successful!');
    console.log('Token:', response.data.token ? 'Token received' : 'No token');
    console.log('User:', response.data.user);
    
    // Test protected route
    const pairsResponse = await axios.get('http://localhost:5000/api/pairs', {
      headers: {
        'Authorization': `Bearer ${response.data.token}`
      }
    });
    
    console.log('Pairs API working! Found', pairsResponse.data.length, 'pairs');
    
  } catch (error) {
    console.error('Error:', error.response ? error.response.data : error.message);
  }
}

testLogin();
