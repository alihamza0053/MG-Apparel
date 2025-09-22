-- Migration to fix pairs table schema
-- Run this in your Supabase SQL Editor

-- Drop existing tables if they exist (to ensure clean state)
DROP TABLE IF EXISTS materials CASCADE;
DROP TABLE IF EXISTS feedback CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS goals CASCADE;
DROP TABLE IF EXISTS pairs CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Create users table
CREATE TABLE users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'mentor', 'mentee')),
    organization VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create pairs table with all required columns
CREATE TABLE pairs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    mentor_id UUID REFERENCES users(id) ON DELETE CASCADE,
    mentee_id UUID REFERENCES users(id) ON DELETE CASCADE,
    organization VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'completed')),
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create goals table
CREATE TABLE goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    pair_id UUID REFERENCES pairs(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'Not Started' CHECK (status IN ('Not Started', 'In Progress', 'Completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create sessions table
CREATE TABLE sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    pair_id UUID REFERENCES pairs(id) ON DELETE CASCADE,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create feedback table
CREATE TABLE feedback (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create materials table
CREATE TABLE materials (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    pair_id UUID REFERENCES pairs(id) ON DELETE CASCADE,
    mentor_id UUID REFERENCES users(id) ON DELETE CASCADE,
    url TEXT,
    document TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert sample users (password is 'password123' hashed)
INSERT INTO users (name, email, password, role, organization) VALUES 
('Admin User', 'admin@mentoring.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 'MG Apparel'),
('John Mentor', 'mentor@mentoring.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'mentor', 'MG Apparel'),
('Jane Mentee', 'mentee@mentoring.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'mentee', 'MG Apparel');

-- Insert sample pair
INSERT INTO pairs (mentor_id, mentee_id, organization, start_date, end_date, status) 
SELECT 
    (SELECT id FROM users WHERE role = 'mentor' LIMIT 1),
    (SELECT id FROM users WHERE role = 'mentee' LIMIT 1),
    'MG Apparel',
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '6 months',
    'active';

-- Insert sample goal
INSERT INTO goals (pair_id, title, description)
SELECT 
    (SELECT id FROM pairs LIMIT 1),
    'Complete React Training',
    'Learn React fundamentals and build a project';

-- Insert sample session
INSERT INTO sessions (pair_id, date, notes)
SELECT 
    (SELECT id FROM pairs LIMIT 1),
    NOW(),
    'First mentoring session - discussed learning goals';

-- Disable RLS for development (enable in production)
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE pairs DISABLE ROW LEVEL SECURITY;
ALTER TABLE goals DISABLE ROW LEVEL SECURITY;
ALTER TABLE sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE feedback DISABLE ROW LEVEL SECURITY;
ALTER TABLE materials DISABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_organization ON users(organization);
CREATE INDEX idx_pairs_mentor ON pairs(mentor_id);
CREATE INDEX idx_pairs_mentee ON pairs(mentee_id);
CREATE INDEX idx_goals_pair ON goals(pair_id);
CREATE INDEX idx_sessions_pair ON sessions(pair_id);
CREATE INDEX idx_feedback_session ON feedback(session_id);
CREATE INDEX idx_materials_pair ON materials(pair_id);
