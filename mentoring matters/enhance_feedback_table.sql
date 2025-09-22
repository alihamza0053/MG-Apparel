-- SQL Script to Update Feedback Table with Enhanced Structure
-- Run these commands in your Supabase SQL Editor

-- 1. First, backup existing feedback data (optional but recommended)
CREATE TABLE feedback_backup AS SELECT * FROM feedback;

-- 2. Drop the existing feedback table
DROP TABLE IF EXISTS feedback;

-- 3. Create the enhanced feedback table with all required columns
CREATE TABLE feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    session_date DATE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comments TEXT NOT NULL,
    mentor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    mentee_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    pair_id UUID REFERENCES mentoring_pairs(id) ON DELETE CASCADE
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policies for feedback access

-- Policy for admins (can see all feedback)
CREATE POLICY "Admins can view all feedback" ON feedback
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- Policy for mentors (can see feedback where they are the mentor)
CREATE POLICY "Mentors can view their feedback" ON feedback
FOR SELECT USING (
    mentor_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- Policy for mentees (can see feedback where they are the mentee)
CREATE POLICY "Mentees can view their feedback" ON feedback
FOR SELECT USING (
    mentee_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- Policy for inserting feedback (authenticated users can insert)
CREATE POLICY "Authenticated users can insert feedback" ON feedback
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Policy for updating feedback (users can update their own feedback)
CREATE POLICY "Users can update their own feedback" ON feedback
FOR UPDATE USING (
    mentor_id = auth.uid() OR 
    mentee_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- Policy for deleting feedback (admins can delete, users can delete their own)
CREATE POLICY "Users can delete their feedback" ON feedback
FOR DELETE USING (
    mentor_id = auth.uid() OR 
    mentee_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role = 'admin'
    )
);

-- 6. Create indexes for better performance
CREATE INDEX idx_feedback_mentor_id ON feedback(mentor_id);
CREATE INDEX idx_feedback_mentee_id ON feedback(mentee_id);
CREATE INDEX idx_feedback_pair_id ON feedback(pair_id);
CREATE INDEX idx_feedback_session_date ON feedback(session_date);
CREATE INDEX idx_feedback_created_at ON feedback(created_at DESC);

-- 7. If you want to restore the old feedback data (optional)
-- Note: You'll need to manually map the old data to the new structure
-- INSERT INTO feedback (rating, comments, created_at) 
-- SELECT rating, comments, created_at FROM feedback_backup;

-- 8. Clean up backup table (uncomment if you don't need it)
-- DROP TABLE feedback_backup;

COMMENT ON TABLE feedback IS 'Enhanced feedback table with mentor-mentee relationships';
COMMENT ON COLUMN feedback.session_date IS 'Date when the mentoring session took place';
COMMENT ON COLUMN feedback.mentor_id IS 'ID of the mentor who participated in the session';
COMMENT ON COLUMN feedback.mentee_id IS 'ID of the mentee who participated in the session';
COMMENT ON COLUMN feedback.pair_id IS 'ID of the mentoring pair relationship';