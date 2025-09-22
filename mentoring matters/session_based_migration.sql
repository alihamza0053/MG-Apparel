-- Session-Based Goals and Feedback Migration Script
-- Run these commands in your Supabase SQL Editor

-- 1. Create sessions table with 6 pre-defined sessions
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    session_number INTEGER NOT NULL UNIQUE CHECK (session_number >= 1 AND session_number <= 6),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    duration_weeks INTEGER DEFAULT 2,
    is_active BOOLEAN DEFAULT true
);

-- 2. Insert 6 pre-defined sessions
INSERT INTO sessions (session_number, title, description, duration_weeks) VALUES
(1, 'Getting Started & Goal Setting', 'Initial session to set expectations, understand each other, and establish primary goals', 2),
(2, 'Skill Assessment & Development Plan', 'Assess current skills, identify gaps, and create a development roadmap', 2),
(3, 'Career Path Exploration', 'Explore different career paths, opportunities, and growth strategies', 2),
(4, 'Professional Development', 'Focus on professional skills, networking, and industry knowledge', 2),
(5, 'Project & Portfolio Building', 'Work on practical projects and build a strong professional portfolio', 2),
(6, 'Transition & Next Steps', 'Prepare for transitions, job applications, or next level responsibilities', 2);

-- 3. Backup existing goals table
CREATE TABLE goals_backup AS SELECT * FROM goals;

-- 4. Drop and recreate goals table with session reference
DROP TABLE IF EXISTS goals;

CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    mentor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    mentee_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    pair_id UUID REFERENCES mentoring_pairs(id) ON DELETE CASCADE,
    target_date DATE,
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    status VARCHAR(20) DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed', 'paused')),
    progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    notes TEXT,
    is_mentor_created BOOLEAN DEFAULT false,
    is_mentee_created BOOLEAN DEFAULT false
);

-- 5. Update feedback table to reference sessions instead of being general
-- Backup existing feedback
CREATE TABLE feedback_backup_sessions AS SELECT * FROM feedback;

-- Drop and recreate feedback table
DROP TABLE IF EXISTS feedback;

CREATE TABLE feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    session_date DATE NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comments TEXT NOT NULL,
    mentor_feedback TEXT, -- Feedback from mentor about the session
    mentee_feedback TEXT, -- Feedback from mentee about the session
    mentor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    mentee_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    pair_id UUID REFERENCES mentoring_pairs(id) ON DELETE CASCADE,
    session_completed BOOLEAN DEFAULT false,
    next_session_goals TEXT, -- Goals for the next session
    feedback_type VARCHAR(20) DEFAULT 'session' CHECK (feedback_type IN ('session', 'overall'))
);

-- 6. Enable Row Level Security for new tables
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- 7. Create RLS policies for sessions (public read, admin write)
CREATE POLICY "Anyone can view sessions" ON sessions
FOR SELECT USING (true);

CREATE POLICY "Admins can manage sessions" ON sessions
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- 8. Create RLS policies for session-based goals
CREATE POLICY "Users can view their goals" ON goals
FOR SELECT USING (
    mentor_id = auth.uid() OR 
    mentee_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

CREATE POLICY "Users can insert their goals" ON goals
FOR INSERT WITH CHECK (
    auth.role() = 'authenticated' AND (
        mentor_id = auth.uid() OR 
        mentee_id = auth.uid()
    )
);

CREATE POLICY "Users can update their goals" ON goals
FOR UPDATE USING (
    mentor_id = auth.uid() OR 
    mentee_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

CREATE POLICY "Users can delete their goals" ON goals
FOR DELETE USING (
    mentor_id = auth.uid() OR 
    mentee_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- 9. Create RLS policies for session-based feedback
CREATE POLICY "Users can view their session feedback" ON feedback
FOR SELECT USING (
    mentor_id = auth.uid() OR 
    mentee_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

CREATE POLICY "Users can insert session feedback" ON feedback
FOR INSERT WITH CHECK (
    auth.role() = 'authenticated' AND (
        mentor_id = auth.uid() OR 
        mentee_id = auth.uid()
    )
);

CREATE POLICY "Users can update their session feedback" ON feedback
FOR UPDATE USING (
    mentor_id = auth.uid() OR 
    mentee_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

CREATE POLICY "Users can delete their session feedback" ON feedback
FOR DELETE USING (
    mentor_id = auth.uid() OR 
    mentee_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- 10. Create indexes for better performance
CREATE INDEX idx_goals_session_id ON goals(session_id);
CREATE INDEX idx_goals_mentor_id ON goals(mentor_id);
CREATE INDEX idx_goals_mentee_id ON goals(mentee_id);
CREATE INDEX idx_goals_pair_id ON goals(pair_id);
CREATE INDEX idx_goals_status ON goals(status);
CREATE INDEX idx_goals_priority ON goals(priority);

CREATE INDEX idx_feedback_session_id ON feedback(session_id);
CREATE INDEX idx_feedback_mentor_id ON feedback(mentor_id);
CREATE INDEX idx_feedback_mentee_id ON feedback(mentee_id);
CREATE INDEX idx_feedback_pair_id ON feedback(pair_id);
CREATE INDEX idx_feedback_session_date ON feedback(session_date);
CREATE INDEX idx_feedback_created_at ON feedback(created_at DESC);

CREATE INDEX idx_sessions_number ON sessions(session_number);
CREATE INDEX idx_sessions_active ON sessions(is_active);

-- 11. Add helpful comments
COMMENT ON TABLE sessions IS 'Pre-defined mentoring sessions (6 sessions total)';
COMMENT ON TABLE goals IS 'Session-specific goals for mentor-mentee pairs';
COMMENT ON TABLE feedback IS 'Session-based feedback from mentors and mentees';

COMMENT ON COLUMN goals.session_id IS 'Reference to the specific mentoring session';
COMMENT ON COLUMN goals.is_mentor_created IS 'Whether this goal was created by the mentor';
COMMENT ON COLUMN goals.is_mentee_created IS 'Whether this goal was created by the mentee';

COMMENT ON COLUMN feedback.session_id IS 'Reference to the specific mentoring session';
COMMENT ON COLUMN feedback.mentor_feedback IS 'Feedback provided by the mentor about the session';
COMMENT ON COLUMN feedback.mentee_feedback IS 'Feedback provided by the mentee about the session';
COMMENT ON COLUMN feedback.session_completed IS 'Whether the session has been completed';
COMMENT ON COLUMN feedback.next_session_goals IS 'Goals or expectations for the next session';

-- 12. Create a view for easy session progress tracking
CREATE VIEW session_progress AS
SELECT 
    s.id as session_id,
    s.session_number,
    s.title as session_title,
    mp.id as pair_id,
    mp.mentor_id,
    mp.mentee_id,
    COUNT(g.id) as total_goals,
    COUNT(CASE WHEN g.status = 'completed' THEN 1 END) as completed_goals,
    COUNT(f.id) as feedback_count,
    MAX(f.session_date) as last_session_date,
    CASE 
        WHEN COUNT(f.id) > 0 THEN true 
        ELSE false 
    END as has_feedback
FROM sessions s
CROSS JOIN mentoring_pairs mp
LEFT JOIN goals g ON s.id = g.session_id AND mp.id = g.pair_id
LEFT JOIN feedback f ON s.id = f.session_id AND mp.id = f.pair_id
WHERE mp.status = 'active'
GROUP BY s.id, s.session_number, s.title, mp.id, mp.mentor_id, mp.mentee_id
ORDER BY s.session_number, mp.id;

COMMENT ON VIEW session_progress IS 'Overview of session progress for all active mentoring pairs';