-- SIMPLE FIX - Execute this in Supabase SQL Editor
-- This will definitely work

-- First, delete all existing data to start fresh
DELETE FROM feedback;
DELETE FROM materials;
DELETE FROM goals;
DELETE FROM sessions;
DELETE FROM pairs;
DELETE FROM users;

-- Add users with simple data
INSERT INTO users (id, name, email, password, role, organization) VALUES 
('11111111-1111-1111-1111-111111111111', 'Ali', 'alihamza@gmail.com', '$2a$10$rOvRoi24Kmy7.xKB7V4bU.Vy8GQMK6HHq6gTNyOlpBfQHpf2f2xiq', 'mentor', 'MG Apparel'),
('22222222-2222-2222-2222-222222222222', 'Hamza', 'hamza@gmail.com', '$2a$10$rOvRoi24Kmy7.xKB7V4bU.Vy8GQMK6HHq6gTNyOlpBfQHpf2f2xiq', 'mentee', 'MG Apparel'),
('33333333-3333-3333-3333-333333333333', 'Admin', 'admin@gmail.com', '$2a$10$rOvRoi24Kmy7.xKB7V4bU.Vy8GQMK6HHq6gTNyOlpBfQHpf2f2xiq', 'admin', 'MG Apparel'),
('44444444-4444-4444-4444-444444444444', 'Sarah', 'sarah@gmail.com', '$2a$10$rOvRoi24Kmy7.xKB7V4bU.Vy8GQMK6HHq6gTNyOlpBfQHpf2f2xiq', 'mentor', 'MG Apparel'),
('55555555-5555-5555-5555-555555555555', 'John', 'john@gmail.com', '$2a$10$rOvRoi24Kmy7.xKB7V4bU.Vy8GQMK6HHq6gTNyOlpBfQHpf2f2xiq', 'mentee', 'MG Apparel');

-- Add pairs with fixed IDs
INSERT INTO pairs (id, mentor_id, mentee_id, status, start_date, end_date, organization) VALUES 
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'active', '2025-08-15', '2026-02-15', 'MG Apparel'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444', '55555555-5555-5555-5555-555555555555', 'active', '2025-09-01', '2026-03-01', 'MG Apparel');

-- Add sessions
INSERT INTO sessions (pair_id, date, duration, notes) VALUES 
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', NOW() - INTERVAL '1 week', 60, 'First session with Ali and Hamza'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', NOW() - INTERVAL '3 days', 45, 'Second session - progress review'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', NOW() - INTERVAL '2 days', 30, 'Sarah and John session');

-- Add materials
INSERT INTO materials (pair_id, mentor_id, title, description, type, url) VALUES 
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Learning Guide', 'Basic programming guide for beginners', 'document', 'https://example.com/guide'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Video Tutorial', 'JavaScript basics video', 'video', 'https://example.com/video'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444', 'React Course', 'React development course', 'link', 'https://example.com/react');

-- Add goals
INSERT INTO goals (pair_id, title, description, status) VALUES 
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Learn JavaScript', 'Master JavaScript fundamentals', 'in_progress'),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Build First App', 'Create a web application', 'pending'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Learn React', 'Understand React concepts', 'in_progress');

-- Add feedback
INSERT INTO feedback (pair_id, session_id, mentor_feedback, mentee_feedback, mentor_rating, mentee_rating) VALUES 
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', (SELECT id FROM sessions WHERE pair_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' LIMIT 1), 'Great progress!', 'Very helpful session!', 5, 5),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', (SELECT id FROM sessions WHERE pair_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb' LIMIT 1), 'Good work!', 'Learning a lot!', 4, 4);

-- Show final results
SELECT 'FINAL COUNTS:' as status;
SELECT 'Users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'Pairs', COUNT(*) FROM pairs
UNION ALL
SELECT 'Sessions', COUNT(*) FROM sessions
UNION ALL
SELECT 'Materials', COUNT(*) FROM materials
UNION ALL
SELECT 'Goals', COUNT(*) FROM goals
UNION ALL
SELECT 'Feedback', COUNT(*) FROM feedback;
