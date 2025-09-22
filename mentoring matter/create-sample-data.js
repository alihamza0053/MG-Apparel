// Test script to create sample users and pairs
// Run this in your browser console when logged in as admin

const createSampleData = async () => {
  try {
    console.log('Creating sample users...');
    
    // Create mentor
    await fetch('/api/users', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + localStorage.getItem('token')
      },
      body: JSON.stringify({
        name: 'John Mentor',
        email: 'john.mentor@example.com',
        password: 'password123',
        role: 'mentor'
      })
    });
    
    // Create mentee
    await fetch('/api/users', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + localStorage.getItem('token')
      },
      body: JSON.stringify({
        name: 'Jane Mentee',
        email: 'jane.mentee@example.com',
        password: 'password123',
        role: 'mentee'
      })
    });
    
    console.log('Sample users created! Now refresh the page and create a pair.');
  } catch (error) {
    console.error('Error creating sample data:', error);
  }
};

// Uncomment the line below and run in browser console:
// createSampleData();
