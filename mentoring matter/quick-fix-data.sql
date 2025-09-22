-- Quick fix for missing data - Execute this in Supabase SQL Editor

-- First, let's see what we currently have
SELECT 'Current Users:' as info, COUNT(*) as count FROM users
UNION ALL
SELECT 'Current Pairs:', COUNT(*) FROM pairs;

-- Show existing pairs to avoid duplicates
SELECT 'Existing pairs:' as info, 
       m.email as mentor_email, 
       e.email as mentee_email,
       p.status
FROM pairs p
JOIN users m ON p.mentor_id = m.id
JOIN users e ON p.mentee_id = e.id;

-- First, let's add the missing users if they don't exist
INSERT INTO users (name, email, password, role, organization) 
VALUES 
('Sarah Wilson', 'sarah@gmail.com', '$2a$10$rOvRoi24Kmy7.xKB7V4bU.Vy8GQMK6HHq6gTNyOlpBfQHpf2f2xiq', 'mentor', 'MG Apparel'),
('John Smith', 'john@gmail.com', '$2a$10$rOvRoi24Kmy7.xKB7V4bU.Vy8GQMK6HHq6gTNyOlpBfQHpf2f2xiq', 'mentee', 'MG Apparel'),
('Lisa Chen', 'lisa@gmail.com', '$2a$10$rOvRoi24Kmy7.xKB7V4bU.Vy8GQMK6HHq6gTNyOlpBfQHpf2f2xiq', 'mentee', 'MG Apparel')
ON CONFLICT (email) DO NOTHING;

-- Add missing pairs only if they don't exist
INSERT INTO pairs (mentor_id, mentee_id, status, start_date, end_date, organization)
SELECT 
    m.id as mentor_id,
    e.id as mentee_id,
    'active' as status,
    CURRENT_DATE - INTERVAL '15 days' as start_date,
    CURRENT_DATE + INTERVAL '6 months' as end_date,
    'MG Apparel' as organization
FROM users m, users e 
WHERE m.email = 'sarah@gmail.com' 
  AND e.email = 'john@gmail.com'
  AND NOT EXISTS (
    SELECT 1 FROM pairs p2 
    WHERE p2.mentor_id = m.id AND p2.mentee_id = e.id
  );

INSERT INTO pairs (mentor_id, mentee_id, status, start_date, end_date, organization)
SELECT 
    m.id as mentor_id,
    e.id as mentee_id,
    'active' as status,
    CURRENT_DATE - INTERVAL '7 days' as start_date,
    CURRENT_DATE + INTERVAL '6 months' as end_date,
    'MG Apparel' as organization
FROM users m, users e 
WHERE m.email = 'alihamza@gmail.com' 
  AND e.email = 'lisa@gmail.com'
  AND NOT EXISTS (
    SELECT 1 FROM pairs p2 
    WHERE p2.mentor_id = m.id AND p2.mentee_id = e.id
  );

-- Add materials (this is crucial for material sharing to work)
INSERT INTO materials (pair_id, mentor_id, title, description, type, url)
SELECT 
    p.id,
    p.mentor_id,
    'Programming Fundamentals Guide',
    'Comprehensive guide covering basic programming concepts, syntax, and best practices for beginners',
    'document',
    'https://example.com/programming-guide'
FROM pairs p;

INSERT INTO materials (pair_id, mentor_id, title, description, type, url)
SELECT 
    p.id,
    p.mentor_id,
    'JavaScript Crash Course Video',
    'Video tutorial series covering JavaScript fundamentals with practical examples and exercises',
    'video',
    'https://example.com/javascript-course'
FROM pairs p;

INSERT INTO materials (pair_id, mentor_id, title, description, type, url)
SELECT 
    p.id,
    p.mentor_id,
    'React Development Resources',
    'Collection of resources for learning React including documentation, tutorials, and practice projects',
    'link',
    'https://example.com/react-resources'
FROM pairs p;

-- Add more goals
INSERT INTO goals (pair_id, title, description, status)
SELECT 
    p.id,
    'Build First Web Application',
    'Create a complete web application using HTML, CSS, JavaScript, and a modern framework',
    'pending'
FROM pairs p;

INSERT INTO goals (pair_id, title, description, status)
SELECT 
    p.id,
    'Learn Database Design',
    'Understand database concepts, SQL queries, and how to design efficient database schemas',
    'in_progress'
FROM pairs p;

-- Add feedback entries (this will fix the feedback section)
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
WHERE NOT EXISTS (
    SELECT 1 FROM feedback f WHERE f.pair_id = p.id AND f.session_id = s.id
)
LIMIT 2;

-- Verify the fix
SELECT 'Users:' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'Pairs:', COUNT(*) FROM pairs
UNION ALL
SELECT 'Sessions:', COUNT(*) FROM sessions
UNION ALL
SELECT 'Materials:', COUNT(*) FROM materials  
UNION ALL
SELECT 'Goals:', COUNT(*) FROM goals
UNION ALL
SELECT 'Feedback:', COUNT(*) FROM feedback;
