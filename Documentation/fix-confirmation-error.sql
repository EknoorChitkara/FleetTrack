-- =====================================================
-- FleetTrack - Fix Email Confirmation Error
-- =====================================================
-- This script fixes the "Error confirming user" issue
-- by making the trigger more defensive
-- =====================================================

-- =====================================================
-- Step 1: Drop the problematic trigger first
-- =====================================================

DROP TRIGGER IF EXISTS trigger_sync_verified_user ON auth.users;
DROP TRIGGER IF EXISTS trigger_sync_auth_to_public ON auth.users;
DROP TRIGGER IF EXISTS trigger_sync_new_auth_to_public ON auth.users;

-- =====================================================
-- Step 2: Create a VERY defensive trigger function
-- =====================================================

CREATE OR REPLACE FUNCTION sync_verified_user_to_public()
RETURNS TRIGGER AS $$
BEGIN
    -- Wrap EVERYTHING in exception handling
    -- Never let this trigger fail the auth operation
    BEGIN
        -- Only proceed if email was just confirmed
        IF (TG_OP = 'UPDATE' AND OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL) THEN
            
            -- Insert into public.users with all defaults
            INSERT INTO public.users (
                id, 
                email, 
                name, 
                role, 
                phone_number, 
                is_active, 
                created_at, 
                updated_at
            )
            VALUES (
                NEW.id,
                NEW.email,
                COALESCE(
                    NEW.raw_user_meta_data->>'full_name',
                    NEW.raw_user_meta_data->>'name',
                    split_part(NEW.email, '@', 1)
                ),
                'Driver',  -- Default role, safer than casting
                NEW.raw_user_meta_data->>'phone_number',
                TRUE,
                NOW(),
                NOW()
            )
            ON CONFLICT (id) DO UPDATE SET
                email = EXCLUDED.email,
                updated_at = NOW();
                
        END IF;
    EXCEPTION WHEN OTHERS THEN
        -- Log but NEVER fail
        RAISE WARNING 'sync_verified_user_to_public failed for %: %', NEW.email, SQLERRM;
    END;
    
    -- Always return NEW to not break the operation
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Step 3: Recreate trigger with WHEN clause for safety
-- =====================================================

CREATE TRIGGER trigger_sync_verified_user
    AFTER UPDATE ON auth.users
    FOR EACH ROW
    WHEN (OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL)
    EXECUTE FUNCTION sync_verified_user_to_public();

-- =====================================================
-- Step 4: Make sure public.users -> drivers trigger is also safe
-- =====================================================

CREATE OR REPLACE FUNCTION sync_public_user_to_driver()
RETURNS TRIGGER AS $$
BEGIN
    BEGIN
        IF NEW.role::text = 'Driver' THEN
            INSERT INTO drivers (
                id, user_id, full_name, email, phone_number,
                status, is_active, joined_date, created_at, updated_at
            ) VALUES (
                gen_random_uuid(),
                NEW.id,
                NEW.name,
                NEW.email,
                NEW.phone_number,
                'Available',
                TRUE,
                CURRENT_DATE,
                NOW(),
                NOW()
            )
            ON CONFLICT (user_id) DO NOTHING;
        END IF;
        
        IF NEW.role::text = 'Maintenance Personnel' THEN
            INSERT INTO maintenance_personnel (
                id, user_id, full_name, email, phone_number,
                is_active, created_at, updated_at
            ) VALUES (
                gen_random_uuid(),
                NEW.id,
                NEW.name,
                NEW.email,
                NEW.phone_number,
                TRUE,
                NOW(),
                NOW()
            )
            ON CONFLICT (user_id) DO NOTHING;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'sync_public_user_to_driver failed: %', SQLERRM;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
DROP TRIGGER IF EXISTS trigger_sync_public_user_to_driver ON public.users;
CREATE TRIGGER trigger_sync_public_user_to_driver
    AFTER INSERT ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION sync_public_user_to_driver();

-- =====================================================
-- Step 5: Delete the broken user and recreate
-- =====================================================

-- Replace 'broken-email@example.com' with actual email
-- DELETE FROM auth.identities WHERE user_id = (SELECT id FROM auth.users WHERE email = 'broken-email@example.com');
-- DELETE FROM auth.users WHERE email = 'broken-email@example.com';

-- =====================================================
-- Step 6: Verify
-- =====================================================

SELECT tgname, tgrelid::regclass, tgenabled 
FROM pg_trigger 
WHERE tgname LIKE 'trigger_sync%' 
ORDER BY tgname;

-- =====================================================
-- ALTERNATIVE: If triggers still cause issues,
-- disable all auth.users triggers and use manual sync
-- =====================================================

-- To completely disable auth triggers (if needed):
-- DROP TRIGGER IF EXISTS trigger_sync_verified_user ON auth.users;
-- 
-- Then manually sync after user confirms:
-- INSERT INTO public.users (id, email, name, role, is_active, created_at, updated_at)
-- SELECT id, email, COALESCE(raw_user_meta_data->>'full_name', email), 'Driver', TRUE, NOW(), NOW()
-- FROM auth.users WHERE email = 'confirmed-user@example.com'
-- ON CONFLICT (id) DO NOTHING;
