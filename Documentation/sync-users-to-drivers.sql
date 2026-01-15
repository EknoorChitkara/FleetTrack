-- =====================================================
-- FleetTrack - Sync Public Users to Drivers Table
-- =====================================================
-- This script creates driver records for any public.users
-- with role='Driver' who don't have a drivers record yet.
-- Only essential fields are filled, others are null.
-- =====================================================

-- =====================================================
-- 1. One-time sync: Create drivers records for existing users
-- =====================================================

INSERT INTO drivers (
    id,
    user_id,
    full_name,
    email,
    phone_number,
    address,
    license_number,
    driver_license_number,
    license_type,
    license_expiry_date,
    status,
    rating,
    safety_score,
    total_trips,
    total_distance_driven,
    on_time_delivery_rate,
    fuel_efficiency,
    current_vehicle_id,
    current_trip_id,
    certifications,
    years_of_experience,
    emergency_contact_name,
    emergency_contact_phone,
    is_active,
    joined_date,
    last_active_date,
    created_at,
    updated_at
)
SELECT 
    gen_random_uuid(),           -- id
    pu.id,                       -- user_id (linked to public.users)
    pu.name,                     -- full_name (from public.users)
    pu.email,                    -- email
    pu.phone_number,             -- phone_number
    NULL,                        -- address (null - to be filled later)
    NULL,                        -- license_number (null)
    NULL,                        -- driver_license_number (null)
    NULL,                        -- license_type (null)
    NULL,                        -- license_expiry_date (null)
    'Available',                 -- status (default: Available so they can get trips)
    NULL,                        -- rating (null)
    NULL,                        -- safety_score (null)
    0,                           -- total_trips (0)
    0,                           -- total_distance_driven (0)
    NULL,                        -- on_time_delivery_rate (null)
    NULL,                        -- fuel_efficiency (null)
    NULL,                        -- current_vehicle_id (null)
    NULL,                        -- current_trip_id (null)
    NULL,                        -- certifications (null)
    NULL,                        -- years_of_experience (null)
    NULL,                        -- emergency_contact_name (null)
    NULL,                        -- emergency_contact_phone (null)
    TRUE,                        -- is_active (true - can get trips)
    CURRENT_DATE,                -- joined_date
    NULL,                        -- last_active_date (null)
    NOW(),                       -- created_at
    NOW()                        -- updated_at
FROM public.users pu
WHERE pu.role = 'Driver'
AND NOT EXISTS (
    SELECT 1 FROM drivers d WHERE d.user_id = pu.id
)
ON CONFLICT (user_id) DO NOTHING;

-- =====================================================
-- 2. View the results
-- =====================================================

-- Show all drivers that were just created or already existed
SELECT 
    d.id as driver_id,
    d.user_id,
    d.full_name,
    d.email,
    d.status,
    d.is_active,
    CASE 
        WHEN d.license_number IS NULL THEN 'Needs to complete profile'
        ELSE 'Profile complete'
    END as profile_status
FROM drivers d
ORDER BY d.created_at DESC;

-- =====================================================
-- 3. Create a helper function to sync on-demand
-- =====================================================

CREATE OR REPLACE FUNCTION sync_users_to_drivers()
RETURNS TABLE (
    synced_count INT,
    message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INT := 0;
BEGIN
    -- Insert drivers records for users with role='Driver' who don't have one
    INSERT INTO drivers (
        id, user_id, full_name, email, phone_number,
        status, is_active, joined_date, created_at, updated_at
    )
    SELECT 
        gen_random_uuid(),
        pu.id,
        pu.name,
        pu.email,
        pu.phone_number,
        'Available',
        TRUE,
        CURRENT_DATE,
        NOW(),
        NOW()
    FROM public.users pu
    WHERE pu.role = 'Driver'
    AND NOT EXISTS (SELECT 1 FROM drivers d WHERE d.user_id = pu.id);
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    
    RETURN QUERY SELECT v_count, format('%s new driver records created', v_count);
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION sync_users_to_drivers TO authenticated;

-- =====================================================
-- 4. USAGE
-- =====================================================

-- Run manually whenever you want to sync:
-- SELECT * FROM sync_users_to_drivers();

-- Or call from the app via RPC:
-- try await client.rpc("sync_users_to_drivers").execute()

-- =====================================================
-- 5. Verify
-- =====================================================

-- Check users with role='Driver'
SELECT 'public.users' as source, id, email, name, role 
FROM public.users WHERE role = 'Driver';

-- Check corresponding drivers records
SELECT 'drivers' as source, id, user_id, email, full_name, status, is_active
FROM drivers WHERE user_id IN (SELECT id FROM public.users WHERE role = 'Driver');
