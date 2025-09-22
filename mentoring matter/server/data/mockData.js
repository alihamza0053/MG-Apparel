// Simple in-memory storage for development/testing
let users = [
  {
    _id: '1',
    name: 'Admin User',
    email: 'admin@test.com',
    password: '$2a$10$8Vu5mWFSd7PQjEHh7SqFzOxAM1bxJ7YE8qFPJ3JJKuOx.YK8M9b5W', // password: admin123
    role: 'admin',
    organization: 'Test Org'
  },
  {
    _id: '2',
    name: 'Mentor User',
    email: 'mentor@test.com',
    password: '$2a$10$8Vu5mWFSd7PQjEHh7SqFzOxAM1bxJ7YE8qFPJ3JJKuOx.YK8M9b5W', // password: admin123
    role: 'mentor',
    organization: 'Test Org'
  },
  {
    _id: '3',
    name: 'Mentee User',
    email: 'mentee@test.com',
    password: '$2a$10$8Vu5mWFSd7PQjEHh7SqFzOxAM1bxJ7YE8qFPJ3JJKuOx.YK8M9b5W', // password: admin123
    role: 'mentee',
    organization: 'Test Org'
  }
];

let pairs = [];
let goals = [];
let sessions = [];
let feedback = [];
let materials = [];

module.exports = {
  users,
  pairs,
  goals,
  sessions,
  feedback,
  materials
};
