import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from './supabaseClient';
import { User } from './types';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string, fullName: string, role: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [profileCache, setProfileCache] = useState<{ [key: string]: User }>({});

  useEffect(() => {
    let isMounted = true;
    
    // Set a shorter timeout to prevent infinite loading
    const loadingTimeout = setTimeout(() => {
      if (loading && isMounted) {
        console.warn('Loading timeout reached, setting loading to false');
        setLoading(false);
      }
    }, 5000); // Reduced from 10 seconds to 5 seconds

    // Get initial session immediately
    const initializeAuth = async () => {
      try {
        const { data: { session }, error } = await supabase.auth.getSession();
        
        if (!isMounted) return;
        
        if (error) {
          console.error('Session error:', error);
          setLoading(false);
          return;
        }

        if (session?.user) {
          await fetchUserProfile(session.user.id);
        } else {
          setLoading(false);
        }
      } catch (error) {
        console.error('Error initializing auth:', error);
        if (isMounted) {
          setLoading(false);
        }
      }
    };

    initializeAuth();

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (!isMounted) return;
      
      console.log('Auth state change:', event, !!session);
      
      if (session?.user) {
        // Set loading false immediately for better UX
        setLoading(false);
        // Fetch profile in background
        fetchUserProfile(session.user.id);
      } else {
        setUser(null);
        setLoading(false);
      }
    });

    return () => {
      isMounted = false;
      subscription.unsubscribe();
      clearTimeout(loadingTimeout);
    };
  }, []);

  const fetchUserProfile = async (userId: string) => {
    try {
      // Check cache first
      if (profileCache[userId]) {
        console.log('Using cached profile for:', userId);
        setUser(profileCache[userId]);
        setLoading(false);
        return;
      }
      
      // Use select with specific fields only and add timeout
      const timeoutPromise = new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Profile fetch timeout')), 3000)
      );
      
      const fetchPromise = supabase
        .from('profiles')
        .select('id, email, full_name, role, organization_id')
        .eq('id', userId)
        .maybeSingle();

      const { data, error } = await Promise.race([fetchPromise, timeoutPromise]) as any;

      let userData: User;
      
      if (error && error.code !== 'PGRST116') {
        console.error('Error fetching user profile:', error);
        // Create basic user from auth data
        userData = {
          id: userId,
          email: '',
          full_name: 'User',
          role: 'mentee' as const
        };
      } else if (!data) {
        // Profile doesn't exist, create a minimal user object
        console.log('No profile found, creating default user');
        userData = {
          id: userId,
          email: '',
          full_name: 'User',
          role: 'mentee' as const
        };
      } else {
        userData = data;
      }
      
      // Cache the user data
      setProfileCache(prev => ({ ...prev, [userId]: userData }));
      setUser(userData);
    } catch (error) {
      console.error('Profile fetch timeout or error:', error);
      // Create basic user on any error
      const userData = {
        id: userId,
        email: '',
        full_name: 'User',
        role: 'mentee' as const
      };
      setProfileCache(prev => ({ ...prev, [userId]: userData }));
      setUser(userData);
    } finally {
      setLoading(false);
    }
  };

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error) throw error;
  };

  const signUp = async (email: string, password: string, fullName: string, role: string) => {
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
          role: role,
        },
      },
    });
    if (error) throw error;
  };

  const signOut = async () => {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
      
      // Clear user state immediately
      setUser(null);
      setLoading(false);
    } catch (error) {
      console.error('Error signing out:', error);
      throw error;
    }
  };

  const value = {
    user,
    loading,
    signIn,
    signUp,
    signOut,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}