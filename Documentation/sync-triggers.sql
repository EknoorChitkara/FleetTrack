-- =====================================================
-- FleetTrack - Automatic Table Synchronization Triggers
-- Execute this SQL in Supabase SQL Editor
-- =====================================================
-- This script creates triggers that automatically sync
-- the users table with drivers/maintenance_personnel tables
-- when a user is added with a specific role.
-- =====================================================

-- =====================================================
-- 1. TRIGGER: Auto-create driver record when user with role='Driver' is inserted
-- =====================================================
CREATE OR REPLACE FUNCTION sync_user_to_driver()
RETURNS TRIGGER AS $$
BEGIN
    -- When a new user with role 'Driver' is inserted into users table
    IF NEW.role = 'Driver' THEN
        INSERT INTO drivers (
            id,
            user_id,
            full_name,
            email,
            phone_number,
            status,
            is_active,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            NEW.id,
            NEW.name,
            NEW.email,
            NEW.phone_number,
            'Available',
            TRUE,
            NOW(),
            NOW()
        )
        ON CONFLICT (user_id) DO NOTHING; -- Prevent duplicates
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS trigger_sync_user_to_driver ON users;
CREATE TRIGGER trigger_sync_user_to_driver
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION sync_user_to_driver();

-- =====================================================
-- 2. TRIGGER: Auto-update driver record when user is updated
-- =====================================================
CREATE OR REPLACE FUNCTION sync_user_update_to_driver()
RETURNS TRIGGER AS $$
BEGIN
    -- If role changed FROM something else TO 'Driver'
    IF OLD.role != 'Driver' AND NEW.role = 'Driver' THEN
        INSERT INTO drivers (
            id,
            user_id,
            full_name,
            email,
            phone_number,
            status,
            is_active,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            NEW.id,
            NEW.name,
            NEW.email,
            NEW.phone_number,
            'Available',
            TRUE,
            NOW(),
            NOW()
        )
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
    
    -- If user info is updated and they are a driver, sync changes
    IF NEW.role = 'Driver' THEN
        UPDATE drivers
        SET 
            full_name = NEW.name,
            email = NEW.email,
            phone_number = NEW.phone_number,
            is_active = NEW.is_active,
            updated_at = NOW()
        WHERE user_id = NEW.id;
    END IF;
    
    -- If role changed FROM 'Driver' to something else, deactivate driver record
    IF OLD.role = 'Driver' AND NEW.role != 'Driver' THEN
        UPDATE drivers
        SET is_active = FALSE, updated_at = NOW()
        WHERE user_id = NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_sync_user_update_to_driver ON users;
CREATE TRIGGER trigger_sync_user_update_to_driver
    AFTER UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION sync_user_update_to_driver();

-- =====================================================
-- 3. TRIGGER: Auto-create maintenance_personnel record
-- =====================================================
CREATE OR REPLACE FUNCTION sync_user_to_maintenance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.role = 'Maintenance Personnel' THEN
        INSERT INTO maintenance_personnel (
            id,
            user_id,
            employee_id,
            status,
            is_active,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            NEW.id,
            'EMP-' || SUBSTRING(NEW.id::text FROM 1 FOR 8), -- Auto-generate employee_id
            'Available',
            TRUE,
            NOW(),
            NOW()
        )
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_sync_user_to_maintenance ON users;
CREATE TRIGGER trigger_sync_user_to_maintenance
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION sync_user_to_maintenance();

-- =====================================================
-- 4. TRIGGER: Auto-update maintenance_personnel on user update
-- =====================================================
CREATE OR REPLACE FUNCTION sync_user_update_to_maintenance()
RETURNS TRIGGER AS $$
BEGIN
    -- If role changed TO 'Maintenance Personnel'
    IF OLD.role != 'Maintenance Personnel' AND NEW.role = 'Maintenance Personnel' THEN
        INSERT INTO maintenance_personnel (
            id,
            user_id,
            employee_id,
            status,
            is_active,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            NEW.id,
            'EMP-' || SUBSTRING(NEW.id::text FROM 1 FOR 8),
            'Available',
            TRUE,
            NOW(),
            NOW()
        )
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
    
    -- If role changed FROM 'Maintenance Personnel' to something else
    IF OLD.role = 'Maintenance Personnel' AND NEW.role != 'Maintenance Personnel' THEN
        UPDATE maintenance_personnel
        SET is_active = FALSE, updated_at = NOW()
        WHERE user_id = NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_sync_user_update_to_maintenance ON users;
CREATE TRIGGER trigger_sync_user_update_to_maintenance
    AFTER UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION sync_user_update_to_maintenance();

-- =====================================================
-- 5. Add unique constraint on user_id in drivers table
-- (if not already exists)
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'unique_driver_user_id'
    ) THEN
        ALTER TABLE drivers ADD CONSTRAINT unique_driver_user_id UNIQUE (user_id);
    END IF;
END $$;

-- =====================================================
-- 6. Add unique constraint on user_id in maintenance_personnel
-- (if not already exists)
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'unique_maintenance_user_id'
    ) THEN
        ALTER TABLE maintenance_personnel ADD CONSTRAINT unique_maintenance_user_id UNIQUE (user_id);
    END IF;
END $$;

-- =====================================================
-- 7. VERIFICATION QUERIES
-- =====================================================
-- Run these to verify triggers are installed
SELECT tgname AS trigger_name, tgrelid::regclass AS table_name
FROM pg_trigger 
WHERE tgname LIKE 'trigger_sync%'
ORDER BY tgname;

-- =====================================================
-- 8. TEST: Insert a test user and verify driver is created
-- =====================================================
-- Uncomment and run to test:
-- INSERT INTO users (id, email, name, role) 
-- VALUES (gen_random_uuid(), 'test.driver@example.com', 'Test Driver', 'Driver');
-- 
-- SELECT * FROM drivers WHERE email = 'test.driver@example.com';
