import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://xpqsjxdvifnmlbtemttv.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhwcXNqeGR2aWZubWxidGVtdHR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgwODk5MzUsImV4cCI6MjA3MzY2NTkzNX0.V-CbCrzAXmQgI_YCkItxsq4x_2h8YOo4iflGBDe1McM';

export const supabase = createClient(supabaseUrl, supabaseKey);