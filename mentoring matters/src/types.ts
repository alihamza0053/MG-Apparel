export interface User {
  id: string;
  email: string;
  full_name?: string;
  role: 'admin' | 'mentor' | 'mentee';
  organization_id?: string;
  created_at?: string;
  updated_at?: string;
}

export interface Organization {
  id: string;
  name: string;
  created_at: string;
}

export interface MentoringPair {
  id: string;
  mentor_id: string;
  mentee_id: string;
  organization_id: string;
  status: 'active' | 'inactive' | 'completed';
  created_at: string;
  ended_at?: string;
  mentor?: User;
  mentee?: User;
}

export interface Goal {
  id: string;
  pair_id: string;
  title: string;
  description?: string;
  status: 'not_started' | 'in_progress' | 'completed';
  target_date?: string;
  created_by: string;
  created_at: string;
  updated_at: string;
}

export interface Session {
  id: string;
  pair_id: string;
  title: string;
  description?: string;
  scheduled_at?: string;
  duration_minutes: number;
  status: 'scheduled' | 'completed' | 'cancelled';
  created_at: string;
}

export interface Feedback {
  id: string;
  session_id: string;
  from_user_id: string;
  to_user_id: string;
  rating: number;
  comments?: string;
  created_at: string;
  from_user?: User;
  to_user?: User;
}