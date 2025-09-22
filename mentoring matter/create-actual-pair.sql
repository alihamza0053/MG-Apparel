-- Create a pair with the actual user IDs from your database
-- Run this in your Supabase SQL Editor

-- First, let's see the current users
SELECT 'Current Users:' as info;
SELECT id, name, email, role FROM users ORDER BY role;

-- Insert a pair using the actual user IDs
INSERT INTO pairs (mentor_id, mentee_id, organization, start_date, end_date, status)
VALUES (
    '6d381775-69e7-40a5-aa5f-fddbf8c010d5',  -- ali@gmail.com (mentor)
    '320bdf59-c69f-48fc-8702-c6747e003238',  -- hamza@gmail.com (mentee)
    'MG Apparel',
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '6 months',
    'active'
);

-- Verify the pair was created
SELECT 'Newly Created Pair:' as info;
SELECT 
    p.id as pair_id,
    p.mentor_id,
    mentor.name as mentor_name,
    mentor.email as mentor_email,
    p.mentee_id,
    mentee.name as mentee_name,
    mentee.email as mentee_email,
    p.status,
    p.organization,
    p.start_date,
    p.end_date
FROM pairs p
JOIN users mentor ON p.mentor_id = mentor.id
JOIN users mentee ON p.mentee_id = mentee.id;
