-- Debug and Fix Pairs Issue
-- Run this in Supabase SQL Editor to identify and fix the problem

-- First, let's see what users exist
SELECT 'Current Users:' as info;
SELECT id, name, email, role, organization FROM users ORDER BY role;

-- Now let's see what pairs exist
SELECT 'Current Pairs:' as info;
SELECT id, mentor_id, mentee_id, organization, status FROM pairs;

-- Let's check if the mentor_id and mentee_id in pairs match actual user IDs
SELECT 'Mentor ID Check:' as info;
SELECT 
    p.id as pair_id,
    p.mentor_id,
    u.name as mentor_name
FROM pairs p
LEFT JOIN users u ON p.mentor_id = u.id
WHERE u.role = 'mentor' OR u.role IS NULL;

SELECT 'Mentee ID Check:' as info;
SELECT 
    p.id as pair_id,
    p.mentee_id,
    u.name as mentee_name
FROM pairs p
LEFT JOIN users u ON p.mentee_id = u.id
WHERE u.role = 'mentee' OR u.role IS NULL;

-- Delete all existing pairs (they have wrong IDs)
DELETE FROM pairs;

-- Re-create pairs with correct IDs
INSERT INTO pairs (mentor_id, mentee_id, organization, start_date, end_date, status)
SELECT 
    mentor.id as mentor_id,
    mentee.id as mentee_id,
    'MG Apparel' as organization,
    CURRENT_DATE as start_date,
    CURRENT_DATE + INTERVAL '6 months' as end_date,
    'active' as status
FROM 
    (SELECT id FROM users WHERE role = 'mentor' AND organization = 'MG Apparel' LIMIT 1) mentor
CROSS JOIN 
    (SELECT id FROM users WHERE role = 'mentee' AND organization = 'MG Apparel' LIMIT 1) mentee;

-- Verify the fix
SELECT 'Fixed Pairs:' as info;
SELECT 
    p.id as pair_id,
    p.mentor_id,
    mentor.name as mentor_name,
    p.mentee_id,
    mentee.name as mentee_name,
    p.status,
    p.organization
FROM pairs p
JOIN users mentor ON p.mentor_id = mentor.id
JOIN users mentee ON p.mentee_id = mentee.id;
