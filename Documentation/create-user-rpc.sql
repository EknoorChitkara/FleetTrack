-- =====================================================
-- FleetTrack - Create User with Email Verification
-- =====================================================
-- This RPC function creates users in auth.users WITHOUT
-- auto-confirming the email. User must verify email first.
-- After verification, triggers sync to public.users → drivers
-- =====================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =====================================================
-- RPC Function: Create user requiring email verification
-- =====================================================

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
    v_confirmation_token TEXT;
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
    
    -- Generate a confirmation token
    v_confirmation_token := encode(gen_random_bytes(32), 'hex');
    
    -- Create user in auth.users WITHOUT confirming email
    -- email_confirmed_at = NULL means user must verify email first
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,           -- NULL = not confirmed, requires verification
        confirmation_token,
        confirmation_sent_at,
        raw_user_meta_data,
        raw_app_meta_data,
        created_at,
        updated_at,
        recovery_token,
        email_change_token_new,
        email_change,
        aud,
        role,
        is_super_admin
    ) VALUES (
        v_user_id,
        '00000000-0000-0000-0000-000000000000',
        p_email,
        crypt(p_password, gen_salt('bf')),
        NULL,                          -- ← NOT CONFIRMED - requires email verification
        v_confirmation_token,
        NOW(),                         -- Confirmation email sent now
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
        'authenticated',
        'authenticated',
        false
    );
    
    -- Create identity for email provider
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
            'email_verified', false    -- Not verified yet
        ),
        'email',
        v_user_id::text,
        NULL,                          -- Never signed in
        NOW(),
        NOW()
    );
    
    -- DO NOT create public.users or drivers here
    -- Triggers will create them after email verification
    
    -- Return success
    RETURN jsonb_build_object(
        'success', true,
        'userId', v_user_id,
        'message', 'User created. Verification email will be sent.',
        'requiresVerification', true
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
-- Test
-- =====================================================
-- SELECT create_fleet_user_rpc(
--     'newdriver@example.com',
--     'Password123!',
--     'New Driver',
--     'Driver',
--     '+91-9876543210'
-- );
