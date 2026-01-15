-- =====================================================
-- FleetTrack - Fix Login Error
-- =====================================================
-- Run this in Supabase SQL Editor to fix the 
-- "Database error granting user" issue
-- =====================================================

-- =====================================================
-- Step 1: Disable the auth.users trigger that causes issues
-- =====================================================
-- The trigger was causing conflicts during the login grant process
-- Since our RPC function already creates public.users, we don't need this trigger

DROP TRIGGER IF EXISTS trigger_sync_auth_to_public ON auth.users;
DROP TRIGGER IF EXISTS trigger_sync_new_auth_to_public ON auth.users;

-- =====================================================
-- Step 2: Update the RPC function to be more robust
-- =====================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION create_fleet_user_rpc(
    p_email TEXT,
    p_password TEXT,
    p_full_name TEXT,
    p_role TEXT DEFAULT 'Driver',
    p_phone_number TEXT DEFAULT NULL,
    p_license_number TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_user_id UUID;
    v_driver_id UUID;
BEGIN
    -- Validate inputs
    IF p_email IS NULL OR p_email = '' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Email is required');
    END IF;
    
    IF p_password IS NULL OR length(p_password) < 6 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Password must be at least 6 characters');
    END IF;
    
    -- Check if user already exists
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
        RETURN jsonb_build_object('success', false, 'error', 'User with this email already exists');
    END IF;
    
    -- Generate UUID for new user
    v_user_id := gen_random_uuid();
    
    -- Create user in auth.users with all required fields
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_user_meta_data,
        raw_app_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        recovery_token,
        email_change_token_new,
        email_change,
        aud,
        role,
        is_super_admin,
        last_sign_in_at
    ) VALUES (
        v_user_id,
        '00000000-0000-0000-0000-000000000000',
        p_email,
        crypt(p_password, gen_salt('bf')),
        NOW(),  -- Auto-confirm email
        jsonb_build_object(
            'full_name', p_full_name,
            'role', p_role,
            'phone_number', p_phone_number,
            'license_number', p_license_number,
            'address', p_address
        ),
        jsonb_build_object(
            'provider', 'email',
            'providers', ARRAY['email']
        ),
        NOW(),
        NOW(),
        '',
        '',
        '',
        '',
        'authenticated',
        'authenticated',
        false,
        NOW()
    );
    
    -- Create identity for email provider (REQUIRED for login to work)
    INSERT INTO auth.identities (
        id,
        user_id,
        identity_data,
        provider,
        provider_id,
        last_sign_in_at,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        v_user_id,
        jsonb_build_object(
            'sub', v_user_id::text,
            'email', p_email,
            'email_verified', true,
            'phone_verified', false
        ),
        'email',
        v_user_id::text,
        NOW(),
        NOW(),
        NOW()
    );
    
    -- Create public.users entry
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
        v_user_id,
        p_email,
        p_full_name,
        p_role::user_role,
        p_phone_number,
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
    
    -- For drivers, also create entry in drivers table directly
    -- (don't rely on triggers during this transaction)
    IF p_role = 'Driver' THEN
        v_driver_id := gen_random_uuid();
        INSERT INTO drivers (
            id,
            user_id,
            full_name,
            email,
            phone_number,
            address,
            license_number,
            status,
            is_active,
            created_at,
            updated_at
        ) VALUES (
            v_driver_id,
            v_user_id,
            p_full_name,
            p_email,
            p_phone_number,
            p_address,
            p_license_number,
            'Available',
            TRUE,
            NOW(),
            NOW()
        )
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
    
    -- Return success with all IDs
    RETURN jsonb_build_object(
        'success', true,
        'userId', v_user_id,
        'driverId', v_driver_id,
        'message', 'User created successfully'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', false,
        'error', SQLERRM,
        'detail', SQLSTATE
    );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION create_fleet_user_rpc TO authenticated;
GRANT EXECUTE ON FUNCTION create_fleet_user_rpc TO anon;

-- =====================================================
-- Step 3: Fix any existing users that might have issues
-- =====================================================

-- Add unique constraint on drivers.user_id if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'unique_driver_user_id'
    ) THEN
        ALTER TABLE drivers ADD CONSTRAINT unique_driver_user_id UNIQUE (user_id);
    END IF;
EXCEPTION WHEN OTHERS THEN
    NULL; -- Ignore if already exists
END $$;

-- =====================================================
-- Step 4: Test the fix
-- =====================================================
-- After running this script, try creating a new user:

-- SELECT create_fleet_user_rpc(
--     'newdriver@example.com',
--     'Password123!',
--     'New Driver',
--     'Driver',
--     '+91-9876543210',
--     'DL-2024-001',
--     '123 Main St'
-- );

-- Then verify:
-- SELECT id, email FROM auth.users WHERE email = 'newdriver@example.com';
-- SELECT * FROM public.users WHERE email = 'newdriver@example.com';
-- SELECT * FROM drivers WHERE email = 'newdriver@example.com';

-- =====================================================
-- IMPORTANT: After running this, the user should be able to login!
-- =====================================================
