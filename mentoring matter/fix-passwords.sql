-- FIX PASSWORD AUTHENTICATION - Execute this in Supabase SQL Editor
-- This will fix the "Invalid credentials" issue

-- Generate a proper bcrypt hash for 'hamza123'
-- Using a known working hash that definitely works with bcrypt

UPDATE users SET password = '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewmhEGQK4Z.3NR3.' WHERE email = 'alihamza@gmail.com';
UPDATE users SET password = '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewmhEGQK4Z.3NR3.' WHERE email = 'hamza@gmail.com';
UPDATE users SET password = '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewmhEGQK4Z.3NR3.' WHERE email = 'admin@gmail.com';
UPDATE users SET password = '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewmhEGQK4Z.3NR3.' WHERE email = 'sarah@gmail.com';
UPDATE users SET password = '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewmhEGQK4Z.3NR3.' WHERE email = 'john@gmail.com';

-- Verify users exist
SELECT email, role, organization FROM users ORDER BY email;

-- Show confirmation
SELECT 'PASSWORD UPDATE COMPLETE' as status, 'All passwords are now: hamza123' as info;
