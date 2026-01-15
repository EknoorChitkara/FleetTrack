-- =====================================================
-- FleetTrack - Auth User to Public User Sync Trigger
-- =====================================================
-- Execute this SQL in Supabase SQL Editor
-- This trigger automatically creates a public.users record
-- when a user verifies their email (email_confirmed_at is set)
-- =====================================================

-- =====================================================
-- 1. TRIGGER: Sync auth.users to public.users on email verification
-- =====================================================
-- This trigger fires when:
-- - A user's email_confirmed_at changes from NULL to a timestamp
-- - Indicating the user has verified their email
-- =====================================================

CREATE OR REPLACE FUNCTION sync_auth_user_to_public()
RETURNS TRIGGER AS $$
DECLARE
    user_role user_role;
    user_name TEXT;
    user_phone TEXT;
BEGIN
    -- Only proceed if email was just confirmed (was NULL, now has value)
    IF OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL THEN
        
        -- Extract metadata from auth.users
        user_name := COALESCE(
            NEW.raw_user_meta_data->>'full_name',
            NEW.raw_user_meta_data->>'name',
            split_part(NEW.email, '@', 1) -- Fallback to email prefix
        );
        
        user_phone := NEW.raw_user_meta_data->>'phone_number';
        
        -- Get role from metadata, default to 'Driver' if not specified
        user_role := COALESCE(
            (NEW.raw_user_meta_data->>'role')::user_role,
            'Driver'::user_role
        );
        
        -- Insert into public.users (this will trigger role-based child table inserts)
        INSERT INTO public.users (
            id,
            email,
            name,
            role,
            phone_number,
            is_active,
            created_at,
            updated_at
        ) VALUES (
            NEW.id,
            NEW.email,
            user_name,
            user_role,
            user_phone,
            TRUE,
            NOW(),
            NOW()
        )
        ON CONFLICT (id) DO UPDATE SET
            email = EXCLUDED.email,
            name = EXCLUDED.name,
            role = EXCLUDED.role,
            phone_number = EXCLUDED.phone_number,
            updated_at = NOW();
        
        RAISE LOG 'User % (%) synced to public.users with role %', NEW.email, NEW.id, user_role;
        
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger on auth.users
DROP TRIGGER IF EXISTS trigger_sync_auth_to_public ON auth.users;
CREATE TRIGGER trigger_sync_auth_to_public
    AFTER UPDATE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION sync_auth_user_to_public();

-- =====================================================
-- 2. ALTERNATIVE: Trigger on INSERT for immediate sync
-- (Use this if you want users created immediately, not after verification)
-- =====================================================

CREATE OR REPLACE FUNCTION sync_new_auth_user_to_public()
RETURNS TRIGGER AS $$
DECLARE
    v_role user_role;
    v_name TEXT;
    v_phone TEXT;
BEGIN
    -- Extract metadata from auth.users
    v_name := COALESCE(
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'name',
        split_part(NEW.email, '@', 1)
    );
    
    v_phone := NEW.raw_user_meta_data->>'phone_number';
    
    -- Get role from metadata, default to 'Driver'
    BEGIN
        v_role := COALESCE(
            (NEW.raw_user_meta_data->>'role')::user_role,
            'Driver'::user_role
        );
    EXCEPTION WHEN OTHERS THEN
        v_role := 'Driver'::user_role;
    END;
    
    -- Insert into public.users
    INSERT INTO public.users (
        id,
        email,
        name,
        role,
        phone_number,
        is_active,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        NEW.email,
        v_name,
        v_role,
        v_phone,
        TRUE,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        name = EXCLUDED.name,
        role = EXCLUDED.role,
        phone_number = EXCLUDED.phone_number,
        updated_at = NOW();
    
    RAISE LOG 'New auth user % synced to public.users', NEW.email;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Uncomment to enable immediate sync on user creation:
-- DROP TRIGGER IF EXISTS trigger_sync_new_auth_to_public ON auth.users;
-- CREATE TRIGGER trigger_sync_new_auth_to_public
--     AFTER INSERT ON auth.users
--     FOR EACH ROW
--     EXECUTE FUNCTION sync_new_auth_user_to_public();

-- =====================================================
-- 3. Grant necessary permissions
-- =====================================================

-- Allow the trigger function to insert into public.users
GRANT INSERT, UPDATE ON public.users TO postgres;
GRANT INSERT, UPDATE ON public.users TO service_role;

-- =====================================================
-- 4. VERIFICATION QUERIES
-- =====================================================

-- Check triggers on auth.users
SELECT 
    tgname AS trigger_name,
    tgrelid::regclass AS table_name,
    tgenabled AS enabled
FROM pg_trigger 
WHERE tgrelid = 'auth.users'::regclass
ORDER BY tgname;

-- Check all sync triggers
SELECT tgname AS trigger_name, tgrelid::regclass AS table_name
FROM pg_trigger 
WHERE tgname LIKE 'trigger_sync%'
ORDER BY tgname;

-- =====================================================
-- 5. TEST: Verify the flow works
-- =====================================================
-- To test manually:
-- 1. Call the create-user Edge Function
-- 2. Check auth.users: SELECT * FROM auth.users WHERE email = 'test@example.com';
-- 3. Confirm the email (or manually update email_confirmed_at)
-- 4. Check public.users: SELECT * FROM public.users WHERE email = 'test@example.com';
-- 5. Check drivers table: SELECT * FROM drivers WHERE email = 'test@example.com';

-- =====================================================
-- FLOW SUMMARY:
-- =====================================================
-- 1. Fleet Manager calls Edge Function → creates auth.users record
-- 2. User receives verification email and confirms
-- 3. auth.users.email_confirmed_at is set → trigger fires
-- 4. sync_auth_user_to_public() inserts into public.users
-- 5. Existing trigger sync_user_to_driver() creates drivers record (if role = Driver)
-- 6. Or sync_user_to_maintenance() creates maintenance_personnel record
-- =====================================================
