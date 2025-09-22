-- Complete Supabase Database Schema for Mentoring Application
-- Execute this entire script in Supabase SQL Editor

-- Drop all existing tables to start fresh
DROP TABLE IF EXISTS feedback CASCADE;
DROP TABLE IF EXISTS materials CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS goals CASCADE;
DROP TABLE IF EXISTS pairs CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 1. Create users table
CREATE TABLE users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('mentor', 'mentee', 'admin')),
    organization VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create pairs table
CREATE TABLE pairs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    mentor_id UUID REFERENCES users(id) ON DELETE CASCADE,
    mentee_id UUID REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused', 'cancelled')),
    start_date DATE NOT NULL,
    end_date DATE,
    organization VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(mentor_id, mentee_id)
);

-- 3. Create goals table
CREATE TABLE goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    pair_id UUID REFERENCES pairs(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create sessions table
CREATE TABLE sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    pair_id UUID REFERENCES pairs(id) ON DELETE CASCADE,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTEGER, -- duration in minutes
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create materials table
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

-- 6. Create feedback table
CREATE TABLE feedback (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    pair_id UUID REFERENCES pairs(id) ON DELETE CASCADE,
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    mentor_feedback TEXT,
    mentee_feedback TEXT,
    mentor_rating INTEGER CHECK (mentor_rating >= 1 AND mentor_rating <= 5),
    mentee_rating INTEGER CHECK (mentee_rating >= 1 AND mentee_rating <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert sample users (passwords are hashed for 'hamza123')
INSERT INTO users (name, email, password, role, organization) VALUES 
('ali', 'alihamza@gmail.com', '$2a$10$rOvRoi24Kmy7.xKB7V4bU.Vy8GQMK6HHq6gTNyOlpBfQHpf2f2xiq', 'mentor', 'MG Apparel'),
('Hamza', 'hamza@gmail.com', '$2a$10$rOvRoi24Kmy7.xKB7V4bU.Vy8GQMK6HHq6gTNyOlpBfQHpf2f2xiq', 'mentee', 'MG Apparel'),
('Admin User', 'admin@gmail.com', '$2a$10$rOvRoi24Kmy7.xKB7V4bU.Vy8GQMK6HHq6gTNyOlpBfQHpf2f2xiq', 'admin', 'MG Apparel'),
('Sarah Wilson', 'sarah@gmail.com', '$2a$10$rOvRoi24Kmy7.xKB7V4bU.Vy8GQMK6HHq6gTNyOlpBfQHpf2f2xiq', 'mentor', 'MG Apparel'),
('John Smith', 'john@gmail.com', '$2a$10$rOvRoi24Kmy7.xKB7V4bU.Vy8GQMK6HHq6gTNyOlpBfQHpf2f2xiq', 'mentee', 'MG Apparel'),
('Lisa Chen', 'lisa@gmail.com', '$2a$10$rOvRoi24Kmy7.xKB7V4bU.Vy8GQMK6HHq6gTNyOlpBfQHpf2f2xiq', 'mentee', 'MG Apparel');

-- Insert sample pairs
INSERT INTO pairs (mentor_id, mentee_id, status, start_date, end_date, organization)
SELECT 
    m.id as mentor_id,
    e.id as mentee_id,
    'active' as status,
    CURRENT_DATE - INTERVAL '30 days' as start_date,
    CURRENT_DATE + INTERVAL '6 months' as end_date,
    'MG Apparel' as organization
FROM users m, users e 
WHERE m.email = 'alihamza@gmail.com' AND e.email = 'hamza@gmail.com';

INSERT INTO pairs (mentor_id, mentee_id, status, start_date, end_date, organization)
SELECT 
    m.id as mentor_id,
    e.id as mentee_id,
    'active' as status,
    CURRENT_DATE - INTERVAL '15 days' as start_date,
    CURRENT_DATE + INTERVAL '6 months' as end_date,
    'MG Apparel' as organization
FROM users m, users e 
WHERE m.email = 'sarah@gmail.com' AND e.email = 'john@gmail.com';

INSERT INTO pairs (mentor_id, mentee_id, status, start_date, end_date, organization)
SELECT 
    m.id as mentor_id,
    e.id as mentee_id,
    'active' as status,
    CURRENT_DATE - INTERVAL '7 days' as start_date,
    CURRENT_DATE + INTERVAL '6 months' as end_date,
    'MG Apparel' as organization
FROM users m, users e 
WHERE m.email = 'alihamza@gmail.com' AND e.email = 'lisa@gmail.com';

-- Insert sample sessions
INSERT INTO sessions (pair_id, date, duration, notes)
SELECT 
    p.id,
    NOW() - INTERVAL '1 week',
    60,
    'Initial mentoring session - discussed career goals and created learning roadmap'
FROM pairs p
LIMIT 3;

INSERT INTO sessions (pair_id, date, duration, notes)
SELECT 
    p.id,
    NOW() - INTERVAL '3 days',
    45,
    'Follow-up session - reviewed progress on first assignment and answered questions'
FROM pairs p
LIMIT 3;

INSERT INTO sessions (pair_id, date, duration, notes)
SELECT 
    p.id,
    NOW() - INTERVAL '1 day',
    30,
    'Quick check-in session - provided guidance on current project challenges'
FROM pairs p
LIMIT 2;

-- Insert sample materials
INSERT INTO materials (pair_id, mentor_id, title, description, type, url)
SELECT 
    p.id,
    p.mentor_id,
    'Programming Fundamentals Guide',
    'Comprehensive guide covering basic programming concepts, syntax, and best practices for beginners',
    'document',
    'https://example.com/programming-guide'
FROM pairs p
LIMIT 3;

INSERT INTO materials (pair_id, mentor_id, title, description, type, url)
SELECT 
    p.id,
    p.mentor_id,
    'JavaScript Crash Course Video',
    'Video tutorial series covering JavaScript fundamentals with practical examples and exercises',
    'video',
    'https://example.com/javascript-course'
FROM pairs p
LIMIT 3;

INSERT INTO materials (pair_id, mentor_id, title, description, type, url)
SELECT 
    p.id,
    p.mentor_id,
    'React Development Resources',
    'Collection of resources for learning React including documentation, tutorials, and practice projects',
    'link',
    'https://example.com/react-resources'
FROM pairs p
LIMIT 2;

-- Insert sample goals
INSERT INTO goals (pair_id, title, description, status)
SELECT 
    p.id,
    'Master Programming Fundamentals',
    'Learn and understand core programming concepts including variables, functions, loops, and data structures',
    'in_progress'
FROM pairs p
LIMIT 3;

INSERT INTO goals (pair_id, title, description, status)
SELECT 
    p.id,
    'Build First Web Application',
    'Create a complete web application using HTML, CSS, JavaScript, and a modern framework',
    'pending'
FROM pairs p
LIMIT 3;

INSERT INTO goals (pair_id, title, description, status)
SELECT 
    p.id,
    'Learn Database Design',
    'Understand database concepts, SQL queries, and how to design efficient database schemas',
    'pending'
FROM pairs p
LIMIT 2;

INSERT INTO goals (pair_id, title, description, status)
SELECT 
    p.id,
    'Complete Code Review Process',
    'Learn how to conduct and receive code reviews, understanding best practices for collaborative development',
    'completed'
FROM pairs p
LIMIT 1;

-- Insert sample feedback
INSERT INTO feedback (pair_id, session_id, mentor_feedback, mentee_feedback, mentor_rating, mentee_rating)
SELECT 
    p.id,
    s.id,
    'Excellent progress! The mentee is grasping concepts quickly and asking thoughtful questions. Keep up the great work!',
    'Very helpful session. The mentor explained everything clearly and provided great examples. Looking forward to the next session.',
    5,
    5
FROM pairs p
JOIN sessions s ON s.pair_id = p.id
LIMIT 3;

INSERT INTO feedback (pair_id, session_id, mentor_feedback, mentee_feedback, mentor_rating, mentee_rating)
SELECT 
    p.id,
    s.id,
    'Good session today. The mentee completed the assigned tasks and showed improvement in problem-solving skills.',
    'Learned a lot today. The hands-on exercises were particularly helpful in understanding the concepts.',
    4,
    4
FROM pairs p
JOIN sessions s ON s.pair_id = p.id
OFFSET 3
LIMIT 2;

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_pairs_mentor_id ON pairs(mentor_id);
CREATE INDEX idx_pairs_mentee_id ON pairs(mentee_id);
CREATE INDEX idx_pairs_status ON pairs(status);
CREATE INDEX idx_sessions_pair_id ON sessions(pair_id);
CREATE INDEX idx_sessions_date ON sessions(date);
CREATE INDEX idx_materials_pair_id ON materials(pair_id);
CREATE INDEX idx_materials_mentor_id ON materials(mentor_id);
CREATE INDEX idx_goals_pair_id ON goals(pair_id);
CREATE INDEX idx_goals_status ON goals(status);
CREATE INDEX idx_feedback_pair_id ON feedback(pair_id);
CREATE INDEX idx_feedback_session_id ON feedback(session_id);

-- Verify data insertion
SELECT 'Users created:' as info, COUNT(*) as count FROM users
UNION ALL
SELECT 'Pairs created:', COUNT(*) FROM pairs
UNION ALL
SELECT 'Sessions created:', COUNT(*) FROM sessions
UNION ALL
SELECT 'Materials created:', COUNT(*) FROM materials  
UNION ALL
SELECT 'Goals created:', COUNT(*) FROM goals
UNION ALL
SELECT 'Feedback entries:', COUNT(*) FROM feedback;
