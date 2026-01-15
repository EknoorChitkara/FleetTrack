-- =====================================================
-- FleetTrack - Complete User Sync Flow
-- =====================================================
-- Flow:
-- 1. auth.users → public.users (auto on email verification)
-- 2. public.users → drivers (auto via trigger OR manual sync)
-- =====================================================

-- =====================================================
-- Step 1: Safe trigger for auth.users → public.users
-- Only fires when email_confirmed_at changes (verification)
-- Uses exception handling to not break login process
-- =====================================================

CREATE OR REPLACE FUNCTION sync_verified_user_to_public()
RETURNS TRIGGER AS $$
DECLARE
    v_role user_role;
    v_name TEXT;
BEGIN
    -- Only proceed if this is an email verification event
    -- (email_confirmed_at changed from NULL to a value)
    IF (TG_OP = 'UPDATE' AND OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL) THEN
        
        -- Extract metadata
        v_name := COALESCE(
            NEW.raw_user_meta_data->>'full_name',
            NEW.raw_user_meta_data->>'name',
            split_part(NEW.email, '@', 1)
        );
        
        -- Get role, default to Driver
        BEGIN
            v_role := COALESCE(
                (NEW.raw_user_meta_data->>'role')::user_role,
                'Driver'::user_role
            );
        EXCEPTION WHEN OTHERS THEN
            v_role := 'Driver'::user_role;
        END;
        
        -- Insert into public.users
        BEGIN
            INSERT INTO public.users (id, email, name, role, phone_number, is_active, created_at, updated_at)
            VALUES (
                NEW.id,
                NEW.email,
                v_name,
                v_role,
                NEW.raw_user_meta_data->>'phone_number',
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
        EXCEPTION WHEN OTHERS THEN
            -- Log but don't fail
            RAISE WARNING 'Could not sync user % to public.users: %', NEW.email, SQLERRM;
        END;
        
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger (only on UPDATE for verification events)
DROP TRIGGER IF EXISTS trigger_sync_verified_user ON auth.users;
CREATE TRIGGER trigger_sync_verified_user
    AFTER UPDATE ON auth.users
    FOR EACH ROW
    WHEN (OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL)
    EXECUTE FUNCTION sync_verified_user_to_public();

-- =====================================================
-- Step 2: Trigger for public.users → drivers
-- When a user with role='Driver' is added to public.users,
-- auto-create a drivers record with null fields
-- =====================================================

CREATE OR REPLACE FUNCTION sync_public_user_to_driver()
RETURNS TRIGGER AS $$
BEGIN
    -- Only for Driver role
    IF NEW.role = 'Driver' THEN
        INSERT INTO drivers (
            id,
            user_id,
            full_name,
            email,
            phone_number,
            status,
            is_active,
            joined_date,
            created_at,
            updated_at
            -- All other fields are NULL by default
        ) VALUES (
            gen_random_uuid(),
            NEW.id,
            NEW.name,
            NEW.email,
            NEW.phone_number,
            'Available',  -- Default status so they can get trips
            TRUE,
            CURRENT_DATE,
            NOW(),
            NOW()
        )
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
    
    -- For Maintenance Personnel
    IF NEW.role = 'Maintenance Personnel' THEN
        INSERT INTO maintenance_personnel (
            id,
            user_id,
            full_name,
            email,
            phone_number,
            is_active,
            created_at,
            updated_at
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
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on public.users INSERT
DROP TRIGGER IF EXISTS trigger_sync_public_user_to_driver ON public.users;
CREATE TRIGGER trigger_sync_public_user_to_driver
    AFTER INSERT ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION sync_public_user_to_driver();

-- Also trigger when role is updated to Driver
DROP TRIGGER IF EXISTS trigger_sync_public_user_role_change ON public.users;
CREATE TRIGGER trigger_sync_public_user_role_change
    AFTER UPDATE OF role ON public.users
    FOR EACH ROW
    WHEN (OLD.role IS DISTINCT FROM NEW.role AND NEW.role IN ('Driver', 'Maintenance Personnel'))
    EXECUTE FUNCTION sync_public_user_to_driver();

-- =====================================================
-- Step 3: Add unique constraint if not exists
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_driver_user_id') THEN
        ALTER TABLE drivers ADD CONSTRAINT unique_driver_user_id UNIQUE (user_id);
    END IF;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_maintenance_user_id') THEN
        ALTER TABLE maintenance_personnel ADD CONSTRAINT unique_maintenance_user_id UNIQUE (user_id);
    END IF;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;

-- =====================================================
-- Step 4: Sync any existing users that are missing
-- =====================================================

-- Sync public.users who are Drivers but not in drivers table
INSERT INTO drivers (id, user_id, full_name, email, phone_number, status, is_active, joined_date, created_at, updated_at)
SELECT gen_random_uuid(), id, name, email, phone_number, 'Available', TRUE, CURRENT_DATE, NOW(), NOW()
FROM public.users WHERE role = 'Driver'
AND id NOT IN (SELECT COALESCE(user_id, '00000000-0000-0000-0000-000000000000') FROM drivers)
ON CONFLICT (user_id) DO NOTHING;

-- =====================================================
-- Step 5: Verify triggers are installed
-- =====================================================

SELECT tgname AS trigger_name, tgrelid::regclass AS table_name
FROM pg_trigger 
WHERE tgname IN (
    'trigger_sync_verified_user',
    'trigger_sync_public_user_to_driver',
    'trigger_sync_public_user_role_change'
)
ORDER BY table_name, tgname;

-- =====================================================
-- COMPLETE FLOW:
-- =====================================================
-- 1. User created in auth.users (via Dashboard, RPC, or sign up)
-- 2. User verifies email
-- 3. trigger_sync_verified_user → creates public.users record
-- 4. trigger_sync_public_user_to_driver → creates drivers record
-- 5. Driver can now receive trips! ✅
-- =====================================================
