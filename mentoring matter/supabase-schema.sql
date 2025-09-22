-- Mentoring Matters Database Schema for Supabase
-- Run this in Supabase SQL Editor

-- Drop existing tables if they exist (for clean setup)
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

-- Create pairs table
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
    status VARCHAR(50) DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create sessions table
CREATE TABLE sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    pair_id UUID REFERENCES pairs(id) ON DELETE CASCADE,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTEGER DEFAULT 60, -- duration in minutes
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create feedback table
CREATE TABLE feedback (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comments TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create materials table
CREATE TABLE materials (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    pair_id UUID REFERENCES pairs(id) ON DELETE CASCADE,
    mentor_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    url TEXT,
    file_path TEXT,
    type VARCHAR(50) DEFAULT 'link' CHECK (type IN ('link', 'document', 'video', 'other')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert sample data for testing
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
    'Learn React Development',
    'Master React fundamentals and build a project';

-- Insert sample session
INSERT INTO sessions (pair_id, date, duration, notes)
SELECT 
    (SELECT id FROM pairs LIMIT 1),
    NOW(),
    60,
    'First mentoring session - introduction and goal setting';

-- Disable RLS for development (you can enable it later with proper policies)
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE pairs DISABLE ROW LEVEL SECURITY;
ALTER TABLE goals DISABLE ROW LEVEL SECURITY;
ALTER TABLE sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE feedback DISABLE ROW LEVEL SECURITY;
ALTER TABLE materials DISABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_organization ON users(organization);
CREATE INDEX IF NOT EXISTS idx_pairs_mentor ON pairs(mentor_id);
CREATE INDEX IF NOT EXISTS idx_pairs_mentee ON pairs(mentee_id);
CREATE INDEX IF NOT EXISTS idx_pairs_organization ON pairs(organization);
CREATE INDEX IF NOT EXISTS idx_goals_pair ON goals(pair_id);
CREATE INDEX IF NOT EXISTS idx_sessions_pair ON sessions(pair_id);
CREATE INDEX IF NOT EXISTS idx_feedback_session ON feedback(session_id);
CREATE INDEX IF NOT EXISTS idx_materials_pair ON materials(pair_id);

-- Optional: If you want to enable RLS later, here are sample policies
-- (Uncomment these after testing without RLS)

/*
-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE pairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid()::text = id::text);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid()::text = id::text);
CREATE POLICY "Allow user registration" ON users FOR INSERT WITH CHECK (true);

-- RLS Policies for pairs table
CREATE POLICY "Users can view own pairs" ON pairs FOR SELECT USING (
    mentor_id::text = auth.uid()::text OR 
    mentee_id::text = auth.uid()::text OR
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- Add more policies as needed...
*/
