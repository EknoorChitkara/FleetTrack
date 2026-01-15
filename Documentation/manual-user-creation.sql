-- =====================================================
-- FleetTrack - Manual User Creation Helper Functions
-- =====================================================
-- Use these functions to manually create users from SQL Editor
-- The triggers will automatically sync to public.users and role tables
-- =====================================================

-- =====================================================
-- 1. Function to create a user with all tables synced
-- =====================================================
CREATE OR REPLACE FUNCTION create_fleet_user(
    p_email TEXT,
    p_name TEXT,
    p_role TEXT DEFAULT 'Driver',  -- 'Admin', 'Fleet Manager', 'Driver', 'Maintenance Personnel'
    p_phone TEXT DEFAULT NULL,
    p_password TEXT DEFAULT 'FleetTrack@123'  -- Temporary password
)
RETURNS TABLE(
    auth_user_id UUID,
    public_user_id UUID,
    role_table_id UUID,
    message TEXT
) AS $$
DECLARE
    v_user_id UUID;
    v_role_id UUID;
    v_role_table TEXT;
BEGIN
    -- Generate user ID
    v_user_id := gen_random_uuid();
    
    -- Create auth.users entry
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
        aud,
        role
    ) VALUES (
        v_user_id,
        '00000000-0000-0000-0000-000000000000',
        p_email,
        crypt(p_password, gen_salt('bf')),
        NOW(),  -- Auto-confirm email
        jsonb_build_object(
            'full_name', p_name,
            'role', p_role,
            'phone_number', p_phone
        ),
        '{"provider": "email", "providers": ["email"]}'::jsonb,
        NOW(),
        NOW(),
        'authenticated',
        'authenticated'
    );
    
    -- Create public.users entry (this triggers role-based table creation)
    INSERT INTO public.users (id, email, name, role, phone_number, is_active, created_at, updated_at)
    VALUES (
        v_user_id,
        p_email,
        p_name,
        p_role::user_role,
        p_phone,
        TRUE,
        NOW(),
        NOW()
    );
    
    -- Get the role-specific table ID
    IF p_role = 'Driver' THEN
        v_role_table := 'drivers';
        SELECT id INTO v_role_id FROM drivers WHERE user_id = v_user_id;
    ELSIF p_role = 'Maintenance Personnel' THEN
        v_role_table := 'maintenance_personnel';
        SELECT id INTO v_role_id FROM maintenance_personnel WHERE user_id = v_user_id;
    ELSE
        v_role_table := 'none';
        v_role_id := NULL;
    END IF;
    
    -- Return results
    RETURN QUERY SELECT 
        v_user_id,
        v_user_id,  -- Same ID for public.users
        v_role_id,
        format('User created successfully. Role: %s, Table: %s, Temp Password: %s', p_role, v_role_table, p_password);
        
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 2. Quick helper functions for specific roles
-- =====================================================

-- Create a Driver
CREATE OR REPLACE FUNCTION create_driver(
    p_email TEXT,
    p_name TEXT,
    p_phone TEXT DEFAULT NULL,
    p_password TEXT DEFAULT 'FleetTrack@123'
)
RETURNS TABLE(user_id UUID, driver_id UUID, message TEXT) AS $$
DECLARE
    v_result RECORD;
BEGIN
    SELECT * INTO v_result FROM create_fleet_user(p_email, p_name, 'Driver', p_phone, p_password);
    RETURN QUERY SELECT v_result.auth_user_id, v_result.role_table_id, v_result.message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a Fleet Manager
CREATE OR REPLACE FUNCTION create_fleet_manager(
    p_email TEXT,
    p_name TEXT,
    p_phone TEXT DEFAULT NULL,
    p_password TEXT DEFAULT 'FleetTrack@123'
)
RETURNS TABLE(user_id UUID, message TEXT) AS $$
DECLARE
    v_result RECORD;
BEGIN
    SELECT * INTO v_result FROM create_fleet_user(p_email, p_name, 'Fleet Manager', p_phone, p_password);
    RETURN QUERY SELECT v_result.auth_user_id, v_result.message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create Maintenance Personnel  
CREATE OR REPLACE FUNCTION create_maintenance_personnel(
    p_email TEXT,
    p_name TEXT,
    p_phone TEXT DEFAULT NULL,
    p_password TEXT DEFAULT 'FleetTrack@123'
)
RETURNS TABLE(user_id UUID, personnel_id UUID, message TEXT) AS $$
DECLARE
    v_result RECORD;
BEGIN
    SELECT * INTO v_result FROM create_fleet_user(p_email, p_name, 'Maintenance Personnel', p_phone, p_password);
    RETURN QUERY SELECT v_result.auth_user_id, v_result.role_table_id, v_result.message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create an Admin
CREATE OR REPLACE FUNCTION create_admin(
    p_email TEXT,
    p_name TEXT,
    p_phone TEXT DEFAULT NULL,
    p_password TEXT DEFAULT 'FleetTrack@123'
)
RETURNS TABLE(user_id UUID, message TEXT) AS $$
DECLARE
    v_result RECORD;
BEGIN
    SELECT * INTO v_result FROM create_fleet_user(p_email, p_name, 'Admin', p_phone, p_password);
    RETURN QUERY SELECT v_result.auth_user_id, v_result.message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 3. USAGE EXAMPLES
-- =====================================================

-- Create a driver:
-- SELECT * FROM create_driver('john@example.com', 'John Doe', '+91-9876543210');

-- Create a fleet manager:
-- SELECT * FROM create_fleet_manager('manager@example.com', 'Jane Manager', '+91-9876543211');

-- Create maintenance personnel:
-- SELECT * FROM create_maintenance_personnel('mech@example.com', 'Mike Mechanic', '+91-9876543212');

-- Create an admin:
-- SELECT * FROM create_admin('admin@example.com', 'Super Admin', '+91-9876543213');

-- Create any role with custom password:
-- SELECT * FROM create_fleet_user('custom@example.com', 'Custom User', 'Driver', '+91-9876543214', 'MySecurePass123!');

-- =====================================================
-- 4. VERIFICATION
-- =====================================================

-- After creating a user, verify:
-- SELECT * FROM auth.users WHERE email = 'john@example.com';
-- SELECT * FROM public.users WHERE email = 'john@example.com';
-- SELECT * FROM drivers WHERE email = 'john@example.com';
