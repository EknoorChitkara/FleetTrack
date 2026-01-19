-- =====================================================
-- Maintenance Personnel Sync Trigger
-- =====================================================
-- This trigger automatically syncs auth.users to maintenance_personnel
-- when a user with role 'Maintenance Personnel' is created
-- =====================================================

-- =====================================================
-- Sync Function
-- =====================================================
CREATE OR REPLACE FUNCTION sync_maintenance_personnel()
RETURNS TRIGGER AS $$
BEGIN
    -- Only sync if role is 'Maintenance Personnel'
    IF NEW.raw_user_meta_data->>'role' = 'Maintenance Personnel' THEN
        INSERT INTO maintenance_personnel (
            user_id,
            full_name,
            email,
            phone_number,
            specializations,
            is_active,
            created_at,
            updated_at
        ) VALUES (
            NEW.id,
            NEW.raw_user_meta_data->>'full_name',
            NEW.email,
            NEW.raw_user_meta_data->>'phone_number',
            CASE 
                WHEN NEW.raw_user_meta_data->'specializations' IS NOT NULL 
                THEN (
                    SELECT string_agg(value::text, ', ')
                    FROM jsonb_array_elements_text(NEW.raw_user_meta_data->'specializations')
                )
                ELSE NULL
            END,
            true,
            NOW(),
            NOW()
        )
        ON CONFLICT (email) DO UPDATE SET
            user_id = NEW.id,
            full_name = EXCLUDED.full_name,
            phone_number = EXCLUDED.phone_number,
            specializations = EXCLUDED.specializations,
            updated_at = NOW();
        
        RAISE NOTICE 'Synced maintenance personnel for user: %', NEW.email;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Attach Trigger to auth.users
-- =====================================================
DROP TRIGGER IF EXISTS on_auth_user_created_sync_maintenance ON auth.users;

CREATE TRIGGER on_auth_user_created_sync_maintenance
AFTER INSERT OR UPDATE ON auth.users
FOR EACH ROW
EXECUTE FUNCTION sync_maintenance_personnel();

-- =====================================================
-- Verification
-- =====================================================
-- Test the trigger by checking if it exists
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created_sync_maintenance';
