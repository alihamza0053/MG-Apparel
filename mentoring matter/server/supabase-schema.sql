-- Supabase SQL Schema for Mentoring Matters
-- Run these commands in your Supabase SQL Editor

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'mentor', 'mentee')),
  organization VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Pairs table
CREATE TABLE IF NOT EXISTS pairs (
  id SERIAL PRIMARY KEY,
  mentor_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  organization VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Pair mentees junction table (for many mentees per mentor)
CREATE TABLE IF NOT EXISTS pair_mentees (
  id SERIAL PRIMARY KEY,
  pair_id INTEGER REFERENCES pairs(id) ON DELETE CASCADE,
  mentee_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(pair_id, mentee_id)
);

-- Goals table
CREATE TABLE IF NOT EXISTS goals (
  id SERIAL PRIMARY KEY,
  pair_id INTEGER REFERENCES pairs(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'Not Started' CHECK (status IN ('Not Started', 'In Progress', 'Completed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Sessions table
CREATE TABLE IF NOT EXISTS sessions (
  id SERIAL PRIMARY KEY,
  pair_id INTEGER REFERENCES pairs(id) ON DELETE CASCADE,
  date TIMESTAMP WITH TIME ZONE NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Feedback table
CREATE TABLE IF NOT EXISTS feedback (
  id SERIAL PRIMARY KEY,
  session_id INTEGER REFERENCES sessions(id) ON DELETE CASCADE,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Materials table
CREATE TABLE IF NOT EXISTS materials (
  id SERIAL PRIMARY KEY,
  pair_id INTEGER REFERENCES pairs(id) ON DELETE CASCADE,
  mentor_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  url TEXT,
  document TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE pairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE pair_mentees ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_organization ON users(organization);
CREATE INDEX IF NOT EXISTS idx_pairs_mentor ON pairs(mentor_id);
CREATE INDEX IF NOT EXISTS idx_pair_mentees_pair ON pair_mentees(pair_id);
CREATE INDEX IF NOT EXISTS idx_pair_mentees_mentee ON pair_mentees(mentee_id);
CREATE INDEX IF NOT EXISTS idx_goals_pair ON goals(pair_id);
CREATE INDEX IF NOT EXISTS idx_sessions_pair ON sessions(pair_id);
CREATE INDEX IF NOT EXISTS idx_feedback_session ON feedback(session_id);
CREATE INDEX IF NOT EXISTS idx_materials_pair ON materials(pair_id);
