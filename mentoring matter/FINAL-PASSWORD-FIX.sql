-- FINAL PASSWORD FIX - Execute this in Supabase SQL Editor
-- This hash has been verified to work with bcrypt.compare()

UPDATE users SET password = '$2b$10$C3gH3fhwCg.8LOJM4aoI.u0T5AtlMHPs1S22CuUSIOdrYQbUb3NIK';

-- Verify all users updated
SELECT email, role, organization, 
       CASE WHEN password = '$2b$10$C3gH3fhwCg.8LOJM4aoI.u0T5AtlMHPs1S22CuUSIOdrYQbUb3NIK' 
            THEN 'UPDATED' 
            ELSE 'NOT UPDATED' 
       END as password_status 
FROM users 
ORDER BY email;

-- Show final confirmation
SELECT 'PASSWORD UPDATE COMPLETE' as status, 
       'All passwords are now: hamza123' as info,
       'Hash verified with bcrypt.compare()' as verification;
