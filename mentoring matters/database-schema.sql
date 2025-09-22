-- Database Schema for Mentoring Matters App
-- Execute these SQL commands in Supabase SQL Editor

-- Enable Row Level Security
ALTER DEFAULT PRIVILEGES GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  role TEXT NOT NULL CHECK (role IN ('admin', 'mentor', 'mentee')),
  organization_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (id)
);

-- Organizations table
CREATE TABLE IF NOT EXISTS public.organizations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Mentoring pairs table
CREATE TABLE IF NOT EXISTS public.mentoring_pairs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  mentor_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  mentee_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  organization_id UUID REFERENCES public.organizations(id),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'completed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  ended_at TIMESTAMP WITH TIME ZONE
);

-- Goals table
CREATE TABLE IF NOT EXISTS public.goals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  pair_id UUID REFERENCES public.mentoring_pairs(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed')),
  target_date DATE,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Sessions table
CREATE TABLE IF NOT EXISTS public.sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  pair_id UUID REFERENCES public.mentoring_pairs(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  scheduled_at TIMESTAMP WITH TIME ZONE,
  duration_minutes INTEGER DEFAULT 60,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Feedback table
CREATE TABLE IF NOT EXISTS public.feedback (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID REFERENCES public.sessions(id) ON DELETE CASCADE,
  from_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  to_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  comments TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Materials table
CREATE TABLE IF NOT EXISTS public.materials (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  pair_id UUID REFERENCES public.mentoring_pairs(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  url TEXT,
  file_path TEXT,
  uploaded_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Add foreign key for organization_id in profiles
ALTER TABLE public.profiles ADD CONSTRAINT fk_profiles_organization 
  FOREIGN KEY (organization_id) REFERENCES public.organizations(id);

-- Row Level Security Policies

-- Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON public.profiles 
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles 
  FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can view all profiles in their org" ON public.profiles 
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = auth.uid() 
      AND p.role = 'admin' 
      AND p.organization_id = profiles.organization_id
    )
  );

-- Organizations
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their organization" ON public.organizations 
  FOR SELECT USING (
    id IN (
      SELECT organization_id FROM public.profiles 
      WHERE profiles.id = auth.uid()
    )
  );

-- Mentoring pairs
ALTER TABLE public.mentoring_pairs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own pairs" ON public.mentoring_pairs 
  FOR ALL USING (mentor_id = auth.uid() OR mentee_id = auth.uid());
CREATE POLICY "Admins can view all pairs in their org" ON public.mentoring_pairs 
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles p 
      WHERE p.id = auth.uid() 
      AND p.role = 'admin' 
      AND p.organization_id = mentoring_pairs.organization_id
    )
  );

-- Goals
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view goals for their pairs" ON public.goals 
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.mentoring_pairs mp 
      WHERE mp.id = goals.pair_id 
      AND (mp.mentor_id = auth.uid() OR mp.mentee_id = auth.uid())
    )
  );

-- Sessions
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view sessions for their pairs" ON public.sessions 
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.mentoring_pairs mp 
      WHERE mp.id = sessions.pair_id 
      AND (mp.mentor_id = auth.uid() OR mp.mentee_id = auth.uid())
    )
  );

-- Feedback
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view feedback they gave or received" ON public.feedback 
  FOR ALL USING (from_user_id = auth.uid() OR to_user_id = auth.uid());

-- Materials
ALTER TABLE public.materials ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view materials for their pairs" ON public.materials 
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.mentoring_pairs mp 
      WHERE mp.id = materials.pair_id 
      AND (mp.mentor_id = auth.uid() OR mp.mentee_id = auth.uid())
    )
  );

-- Create default organization
INSERT INTO public.organizations (name) VALUES ('Default Organization') 
ON CONFLICT DO NOTHING;

-- Functions to handle user creation
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, organization_id)
  VALUES (
    NEW.id, 
    NEW.email, 
    NEW.raw_user_meta_data->>'full_name',
    COALESCE(NEW.raw_user_meta_data->>'role', 'mentee'),
    (SELECT id FROM public.organizations LIMIT 1)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();