-- Updated Sessions Table Creation Script
-- Run this in your Supabase SQL Editor

-- 1. First, let's check what columns exist and add missing ones
DO $$ 
BEGIN
    -- Add session_number column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sessions' AND column_name = 'session_number') THEN
        ALTER TABLE sessions ADD COLUMN session_number INTEGER;
    END IF;
    
    -- Add title column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sessions' AND column_name = 'title') THEN
        ALTER TABLE sessions ADD COLUMN title VARCHAR(255);
    END IF;
    
    -- Add description column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sessions' AND column_name = 'description') THEN
        ALTER TABLE sessions ADD COLUMN description TEXT;
    END IF;
    
    -- Add duration_weeks column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sessions' AND column_name = 'duration_weeks') THEN
        ALTER TABLE sessions ADD COLUMN duration_weeks INTEGER DEFAULT 2;
    END IF;
    
    -- Add is_active column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sessions' AND column_name = 'is_active') THEN
        ALTER TABLE sessions ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
END $$;

-- 2. Create the table if it doesn't exist at all
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    session_number INTEGER,
    title VARCHAR(255),
    description TEXT,
    duration_weeks INTEGER DEFAULT 2,
    is_active BOOLEAN DEFAULT true
);

-- 3. Update constraints and make session_number NOT NULL and UNIQUE
-- First remove any existing constraints
ALTER TABLE sessions DROP CONSTRAINT IF EXISTS sessions_session_number_key;
ALTER TABLE sessions DROP CONSTRAINT IF EXISTS sessions_session_number_check;

-- Update any NULL session_numbers before adding constraints
-- Use a subquery with row_number to assign sequential numbers
WITH numbered_sessions AS (
    SELECT id, row_number() OVER (ORDER BY created_at) as new_session_number
    FROM sessions 
    WHERE session_number IS NULL
)
UPDATE sessions 
SET session_number = numbered_sessions.new_session_number
FROM numbered_sessions 
WHERE sessions.id = numbered_sessions.id;

-- Add constraints
ALTER TABLE sessions ALTER COLUMN session_number SET NOT NULL;
ALTER TABLE sessions ADD CONSTRAINT sessions_session_number_key UNIQUE (session_number);
ALTER TABLE sessions ADD CONSTRAINT sessions_session_number_check CHECK (session_number >= 1);

-- 4. Enable Row Level Security
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policies for sessions
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view sessions" ON sessions;
DROP POLICY IF EXISTS "Admins can manage sessions" ON sessions;
DROP POLICY IF EXISTS "Authenticated users can create sessions" ON sessions;
DROP POLICY IF EXISTS "Authenticated users can update their sessions" ON sessions;
DROP POLICY IF EXISTS "Authenticated users can delete sessions" ON sessions;
DROP POLICY IF EXISTS "Admins and mentors can delete sessions" ON sessions;

-- Anyone can view sessions
CREATE POLICY "Anyone can view sessions" ON sessions
FOR SELECT USING (true);

-- Authenticated users can create new sessions
CREATE POLICY "Authenticated users can create sessions" ON sessions
FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Authenticated users can update sessions (for status changes, etc.)
CREATE POLICY "Authenticated users can update their sessions" ON sessions
FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Only admins and mentors can delete sessions
CREATE POLICY "Admins and mentors can delete sessions" ON sessions
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role IN ('admin', 'mentor')
    )
);

-- Admins can do everything (including bulk operations)
CREATE POLICY "Admins can manage sessions" ON sessions
FOR ALL USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- 6. Insert default 6 sessions if they don't exist
INSERT INTO sessions (session_number, title, description, duration_weeks, is_active) VALUES
(1, 'Getting Started & Goal Setting', 'Initial session to set expectations, understand each other, and establish primary goals', 2, true),
(2, 'Skill Assessment & Development Plan', 'Assess current skills, identify gaps, and create a development roadmap', 2, true),
(3, 'Career Path Exploration', 'Explore different career paths, opportunities, and growth strategies', 2, true),
(4, 'Professional Development', 'Focus on professional skills, networking, and industry knowledge', 2, true),
(5, 'Project & Portfolio Building', 'Work on practical projects and build a strong professional portfolio', 2, true),
(6, 'Transition & Next Steps', 'Prepare for transitions, job applications, or next level responsibilities', 2, true)
ON CONFLICT (session_number) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    duration_weeks = EXCLUDED.duration_weeks,
    is_active = EXCLUDED.is_active;

-- 7. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_sessions_number ON sessions(session_number);
CREATE INDEX IF NOT EXISTS idx_sessions_active ON sessions(is_active);

-- 8. Update goals table to support sessions
DO $$ 
BEGIN
    -- Add session_id column to goals table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'goals' AND column_name = 'session_id') THEN
        ALTER TABLE goals ADD COLUMN session_id UUID REFERENCES sessions(id);
    END IF;
    
    -- Add is_mentor_created column to goals table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'goals' AND column_name = 'is_mentor_created') THEN
        ALTER TABLE goals ADD COLUMN is_mentor_created BOOLEAN DEFAULT false;
    END IF;
    
    -- Add is_mentee_created column to goals table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'goals' AND column_name = 'is_mentee_created') THEN
        ALTER TABLE goals ADD COLUMN is_mentee_created BOOLEAN DEFAULT false;
    END IF;
    
    -- Add status column to goals table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'goals' AND column_name = 'status') THEN
        ALTER TABLE goals ADD COLUMN status VARCHAR(20) DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed', 'paused'));
    ELSE
        -- Update the constraint to ensure 'paused' is included
        ALTER TABLE goals DROP CONSTRAINT IF EXISTS goals_status_check;
        ALTER TABLE goals ADD CONSTRAINT goals_status_check CHECK (status IN ('not_started', 'in_progress', 'completed', 'paused'));
    END IF;
    
    -- Add progress_percentage column to goals table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'goals' AND column_name = 'progress_percentage') THEN
        ALTER TABLE goals ADD COLUMN progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100);
    END IF;
    
    -- Add mentor_id column to goals table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'goals' AND column_name = 'mentor_id') THEN
        ALTER TABLE goals ADD COLUMN mentor_id UUID REFERENCES profiles(id);
    END IF;
    
    -- Add mentee_id column to goals table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'goals' AND column_name = 'mentee_id') THEN
        ALTER TABLE goals ADD COLUMN mentee_id UUID REFERENCES profiles(id);
    END IF;
    
    -- Add pair_id column to goals table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'goals' AND column_name = 'pair_id') THEN
        ALTER TABLE goals ADD COLUMN pair_id UUID REFERENCES mentoring_pairs(id);
    END IF;
    
    -- Add notes column to goals table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'goals' AND column_name = 'notes') THEN
        ALTER TABLE goals ADD COLUMN notes TEXT;
    END IF;
    
    -- Add target_date column to goals table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'goals' AND column_name = 'target_date') THEN
        ALTER TABLE goals ADD COLUMN target_date DATE;
    END IF;
    
    -- Add priority column to goals table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'goals' AND column_name = 'priority') THEN
        ALTER TABLE goals ADD COLUMN priority VARCHAR(10) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high'));
    END IF;
END $$;

-- 9. Complete feedback table update for session-based feedback system
DO $$ 
BEGIN
    -- Add session_id column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'session_id') THEN
        ALTER TABLE feedback ADD COLUMN session_id UUID REFERENCES sessions(id);
    END IF;
    
    -- Add feedback_type column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'feedback_type') THEN
        ALTER TABLE feedback ADD COLUMN feedback_type VARCHAR(50) DEFAULT 'session' CHECK (feedback_type IN ('session', 'goal', 'general', 'progress', 'milestone'));
    END IF;
    
    -- Add session_date column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'session_date') THEN
        ALTER TABLE feedback ADD COLUMN session_date DATE;
    END IF;
    
    -- Add session_duration column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'session_duration') THEN
        ALTER TABLE feedback ADD COLUMN session_duration INTEGER; -- Duration in minutes
    END IF;
    
    -- Add mentor_feedback column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'mentor_feedback') THEN
        ALTER TABLE feedback ADD COLUMN mentor_feedback TEXT;
    END IF;
    
    -- Add mentee_feedback column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'mentee_feedback') THEN
        ALTER TABLE feedback ADD COLUMN mentee_feedback TEXT;
    END IF;
    
    -- Add mentor_rating column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'mentor_rating') THEN
        ALTER TABLE feedback ADD COLUMN mentor_rating INTEGER CHECK (mentor_rating >= 1 AND mentor_rating <= 5);
    END IF;
    
    -- Add mentee_rating column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'mentee_rating') THEN
        ALTER TABLE feedback ADD COLUMN mentee_rating INTEGER CHECK (mentee_rating >= 1 AND mentee_rating <= 5);
    END IF;
    
    -- Add session_status column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'session_status') THEN
        ALTER TABLE feedback ADD COLUMN session_status VARCHAR(20) DEFAULT 'completed' CHECK (session_status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'rescheduled'));
    END IF;
    
    -- Add key_topics column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'key_topics') THEN
        ALTER TABLE feedback ADD COLUMN key_topics TEXT[];
    END IF;
    
    -- Add achievements column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'achievements') THEN
        ALTER TABLE feedback ADD COLUMN achievements TEXT;
    END IF;
    
    -- Add challenges column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'challenges') THEN
        ALTER TABLE feedback ADD COLUMN challenges TEXT;
    END IF;
    
    -- Add action_items column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'action_items') THEN
        ALTER TABLE feedback ADD COLUMN action_items TEXT[];
    END IF;
    
    -- Add resources_shared column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'resources_shared') THEN
        ALTER TABLE feedback ADD COLUMN resources_shared TEXT[];
    END IF;
    
    -- Add comments column to feedback table if it doesn't exist (rename from content if needed)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'comments') THEN
        -- Check if 'content' column exists and rename it to 'comments'
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'content') THEN
            ALTER TABLE feedback RENAME COLUMN content TO comments;
        ELSE
            ALTER TABLE feedback ADD COLUMN comments TEXT;
        END IF;
    END IF;
    
    -- Add next_session_goals column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'next_session_goals') THEN
        ALTER TABLE feedback ADD COLUMN next_session_goals TEXT;
    END IF;
    
    -- Add next_session_date column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'next_session_date') THEN
        ALTER TABLE feedback ADD COLUMN next_session_date DATE;
    END IF;
    
    -- Add mentor_id column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'mentor_id') THEN
        ALTER TABLE feedback ADD COLUMN mentor_id UUID REFERENCES profiles(id);
    END IF;
    
    -- Add mentee_id column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'mentee_id') THEN
        ALTER TABLE feedback ADD COLUMN mentee_id UUID REFERENCES profiles(id);
    END IF;
    
    -- Add pair_id column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'pair_id') THEN
        ALTER TABLE feedback ADD COLUMN pair_id UUID REFERENCES mentoring_pairs(id);
    END IF;
    
    -- Add is_mentor_submitted column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'is_mentor_submitted') THEN
        ALTER TABLE feedback ADD COLUMN is_mentor_submitted BOOLEAN DEFAULT false;
    END IF;
    
    -- Add is_mentee_submitted column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'is_mentee_submitted') THEN
        ALTER TABLE feedback ADD COLUMN is_mentee_submitted BOOLEAN DEFAULT false;
    END IF;
    
    -- Add private_notes column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'private_notes') THEN
        ALTER TABLE feedback ADD COLUMN private_notes TEXT;
    END IF;
    
    -- Add follow_up_required column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'follow_up_required') THEN
        ALTER TABLE feedback ADD COLUMN follow_up_required BOOLEAN DEFAULT false;
    END IF;
    
    -- Add rating column to feedback table if it doesn't exist (general session rating)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'rating') THEN
        ALTER TABLE feedback ADD COLUMN rating INTEGER DEFAULT 5 CHECK (rating >= 1 AND rating <= 5);
    END IF;
    
    -- Add session_completed column to feedback table if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feedback' AND column_name = 'session_completed') THEN
        ALTER TABLE feedback ADD COLUMN session_completed BOOLEAN DEFAULT false;
    END IF;
END $$;

-- 10. Create indexes for better performance on new columns
CREATE INDEX IF NOT EXISTS idx_goals_session_id ON goals(session_id);
CREATE INDEX IF NOT EXISTS idx_goals_pair_id ON goals(pair_id);
CREATE INDEX IF NOT EXISTS idx_goals_mentor_id ON goals(mentor_id);
CREATE INDEX IF NOT EXISTS idx_goals_mentee_id ON goals(mentee_id);
CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(status);
CREATE INDEX IF NOT EXISTS idx_goals_priority ON goals(priority);
CREATE INDEX IF NOT EXISTS idx_goals_target_date ON goals(target_date);

-- Feedback table indexes
CREATE INDEX IF NOT EXISTS idx_feedback_session_id ON feedback(session_id);
CREATE INDEX IF NOT EXISTS idx_feedback_type ON feedback(feedback_type);
CREATE INDEX IF NOT EXISTS idx_feedback_mentor_id ON feedback(mentor_id);
CREATE INDEX IF NOT EXISTS idx_feedback_mentee_id ON feedback(mentee_id);
CREATE INDEX IF NOT EXISTS idx_feedback_pair_id ON feedback(pair_id);
CREATE INDEX IF NOT EXISTS idx_feedback_session_date ON feedback(session_date);
CREATE INDEX IF NOT EXISTS idx_feedback_session_status ON feedback(session_status);
CREATE INDEX IF NOT EXISTS idx_feedback_next_session_date ON feedback(next_session_date);
CREATE INDEX IF NOT EXISTS idx_feedback_mentor_submitted ON feedback(is_mentor_submitted);
CREATE INDEX IF NOT EXISTS idx_feedback_mentee_submitted ON feedback(is_mentee_submitted);
CREATE INDEX IF NOT EXISTS idx_feedback_follow_up_required ON feedback(follow_up_required);
CREATE INDEX IF NOT EXISTS idx_feedback_rating ON feedback(rating);
CREATE INDEX IF NOT EXISTS idx_feedback_session_completed ON feedback(session_completed);

-- 10.5. Update profiles table to add missing avatar_url column
    DO $$ 
    BEGIN
        -- Add avatar_url column to profiles table if it doesn't exist
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'avatar_url') THEN
            ALTER TABLE profiles ADD COLUMN avatar_url TEXT;
        END IF;
        
        -- Add other commonly needed profile columns if they don't exist
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'bio') THEN
            ALTER TABLE profiles ADD COLUMN bio TEXT;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'phone') THEN
            ALTER TABLE profiles ADD COLUMN phone VARCHAR(20);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'linkedin_url') THEN
            ALTER TABLE profiles ADD COLUMN linkedin_url TEXT;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'github_url') THEN
            ALTER TABLE profiles ADD COLUMN github_url TEXT;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'skills') THEN
            ALTER TABLE profiles ADD COLUMN skills TEXT[];
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'expertise_areas') THEN
            ALTER TABLE profiles ADD COLUMN expertise_areas TEXT[];
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'is_active') THEN
            ALTER TABLE profiles ADD COLUMN is_active BOOLEAN DEFAULT true;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'last_login') THEN
            ALTER TABLE profiles ADD COLUMN last_login TIMESTAMP WITH TIME ZONE;
        END IF;
    END $$;

    -- Create indexes for profiles table
    CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
    CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON profiles(is_active);
    CREATE INDEX IF NOT EXISTS idx_profiles_last_login ON profiles(last_login);

-- 11. Add helpful comments
COMMENT ON TABLE sessions IS 'Mentoring sessions (6 default + custom sessions)';
COMMENT ON COLUMN sessions.session_number IS 'Sequential session number (1, 2, 3, etc.)';
COMMENT ON COLUMN sessions.title IS 'Session title/name';
COMMENT ON COLUMN sessions.description IS 'Detailed description of session goals and content';
COMMENT ON COLUMN sessions.duration_weeks IS 'Expected duration of this session in weeks';
COMMENT ON COLUMN sessions.is_active IS 'Whether this session is currently active/available';

COMMENT ON COLUMN goals.session_id IS 'Reference to the session this goal belongs to';
COMMENT ON COLUMN goals.is_mentor_created IS 'Whether this goal was created by the mentor';
COMMENT ON COLUMN goals.is_mentee_created IS 'Whether this goal was created by the mentee';
COMMENT ON COLUMN goals.status IS 'Goal status: not_started, in_progress, completed, paused';
COMMENT ON COLUMN goals.progress_percentage IS 'Goal completion percentage (0-100)';
COMMENT ON COLUMN goals.mentor_id IS 'Reference to the mentor profile';
COMMENT ON COLUMN goals.mentee_id IS 'Reference to the mentee profile';
COMMENT ON COLUMN goals.pair_id IS 'Reference to the mentoring pair';
COMMENT ON COLUMN goals.notes IS 'Additional notes or comments about the goal';
COMMENT ON COLUMN goals.target_date IS 'Target completion date for the goal';
COMMENT ON COLUMN goals.priority IS 'Goal priority: low, medium, high';

-- Comprehensive feedback table comments
COMMENT ON COLUMN feedback.session_id IS 'Reference to the session this feedback is for';
COMMENT ON COLUMN feedback.feedback_type IS 'Type of feedback: session, goal, general, progress, milestone';
COMMENT ON COLUMN feedback.session_date IS 'Date when the feedback session occurred';
COMMENT ON COLUMN feedback.session_duration IS 'Session duration in minutes';
COMMENT ON COLUMN feedback.mentor_feedback IS 'Feedback from mentor about the session';
COMMENT ON COLUMN feedback.mentee_feedback IS 'Feedback from mentee about the session';
COMMENT ON COLUMN feedback.mentor_rating IS 'Mentor rating of session (1-5 scale)';
COMMENT ON COLUMN feedback.mentee_rating IS 'Mentee rating of session (1-5 scale)';
COMMENT ON COLUMN feedback.session_status IS 'Status: scheduled, in_progress, completed, cancelled, rescheduled';
COMMENT ON COLUMN feedback.key_topics IS 'Array of key topics discussed during session';
COMMENT ON COLUMN feedback.achievements IS 'Notable achievements or breakthroughs during session';
COMMENT ON COLUMN feedback.challenges IS 'Challenges faced or obstacles encountered';
COMMENT ON COLUMN feedback.action_items IS 'Array of action items for follow-up';
COMMENT ON COLUMN feedback.resources_shared IS 'Array of resources shared during session';
COMMENT ON COLUMN feedback.comments IS 'General comments about the session';
COMMENT ON COLUMN feedback.next_session_goals IS 'Goals and objectives for the next session';
COMMENT ON COLUMN feedback.next_session_date IS 'Planned date for next session';
COMMENT ON COLUMN feedback.mentor_id IS 'Reference to the mentor profile';
COMMENT ON COLUMN feedback.mentee_id IS 'Reference to the mentee profile';
COMMENT ON COLUMN feedback.pair_id IS 'Reference to the mentoring pair';
COMMENT ON COLUMN feedback.is_mentor_submitted IS 'Whether mentor has submitted their feedback';
COMMENT ON COLUMN feedback.is_mentee_submitted IS 'Whether mentee has submitted their feedback';
COMMENT ON COLUMN feedback.private_notes IS 'Private notes not visible to the other party';
COMMENT ON COLUMN feedback.follow_up_required IS 'Whether this session requires follow-up action';
COMMENT ON COLUMN feedback.rating IS 'General session rating (1-5 scale)';
COMMENT ON COLUMN feedback.session_completed IS 'Whether the session has been completed';

-- Profiles table comments
COMMENT ON COLUMN profiles.avatar_url IS 'URL to user profile picture/avatar';
COMMENT ON COLUMN profiles.bio IS 'User biography or description';
COMMENT ON COLUMN profiles.phone IS 'User phone number';
COMMENT ON COLUMN profiles.linkedin_url IS 'LinkedIn profile URL';
COMMENT ON COLUMN profiles.github_url IS 'GitHub profile URL';
COMMENT ON COLUMN profiles.skills IS 'Array of user skills and competencies';
COMMENT ON COLUMN profiles.expertise_areas IS 'Array of areas of expertise for mentoring';
COMMENT ON COLUMN profiles.is_active IS 'Whether the user profile is active';
COMMENT ON COLUMN profiles.last_login IS 'Timestamp of last user login';

-- 12. Add RLS policies for goals and feedback tables to support session deletion
-- Enable RLS on goals and feedback tables
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Authenticated users can manage goals" ON goals;
DROP POLICY IF EXISTS "Authenticated users can manage feedback" ON feedback;
DROP POLICY IF EXISTS "Anyone can view goals" ON goals;
DROP POLICY IF EXISTS "Anyone can view feedback" ON feedback;
DROP POLICY IF EXISTS "Admins and mentors can delete goals" ON goals;
DROP POLICY IF EXISTS "Admins and mentors can manage goals" ON goals;
DROP POLICY IF EXISTS "Authenticated users can create and update goals" ON goals;

-- Goals table policies
CREATE POLICY "Anyone can view goals" ON goals
FOR SELECT USING (true);

-- Authenticated users can create and update goals
CREATE POLICY "Authenticated users can create and update goals" ON goals
FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update goals" ON goals
FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Only admins and mentors can delete goals
CREATE POLICY "Admins and mentors can delete goals" ON goals
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role IN ('admin', 'mentor')
    )
);

-- Feedback table policies  
CREATE POLICY "Anyone can view feedback" ON feedback
FOR SELECT USING (true);

CREATE POLICY "Authenticated users can manage feedback" ON feedback
FOR ALL USING (auth.uid() IS NOT NULL);