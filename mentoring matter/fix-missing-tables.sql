-- Add missing tables and columns for sessions, materials, and goals

-- Recreate sessions table with proper structure
DROP TABLE IF EXISTS sessions CASCADE;
CREATE TABLE sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    pair_id UUID REFERENCES pairs(id) ON DELETE CASCADE,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTEGER, -- duration in minutes
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recreate materials table with proper structure
DROP TABLE IF EXISTS materials CASCADE;
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

-- Recreate goals table with proper structure
DROP TABLE IF EXISTS goals CASCADE;
CREATE TABLE goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    pair_id UUID REFERENCES pairs(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'in-progress', 'completed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add some sample data
INSERT INTO sessions (pair_id, date, duration, notes) 
SELECT id, NOW() - INTERVAL '1 week', 60, 'Initial mentoring session'
FROM pairs 
LIMIT 3;

INSERT INTO materials (pair_id, mentor_id, title, description, type, url)
SELECT p.id, p.mentor_id, 'Getting Started Guide', 'Comprehensive guide for new mentees', 'document', 'https://example.com/guide'
FROM pairs p
LIMIT 3;

INSERT INTO goals (pair_id, title, description, status)
SELECT id, 'Learn Programming Basics', 'Master fundamental programming concepts', 'in-progress'
FROM pairs
LIMIT 3;
