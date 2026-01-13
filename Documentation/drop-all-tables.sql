-- ⚠️ WARNING: DESTRUCTIVE SCRIPT ⚠️
-- This will DELETE ALL DATA and remove all tables and RLS policies
-- Run this in Supabase SQL Editor
-- 
-- Created: 2026-01-13
-- Purpose: Fresh start for database schema

-- ============================================
-- STEP 1: Disable RLS on all tables
-- ============================================

DO $$ 
DECLARE
    tbl RECORD;
BEGIN
    FOR tbl IN 
        SELECT schemaname, tablename 
        FROM pg_tables 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('ALTER TABLE %I.%I DISABLE ROW LEVEL SECURITY', tbl.schemaname, tbl.tablename);
        RAISE NOTICE 'Disabled RLS on: %.%', tbl.schemaname, tbl.tablename;
    END LOOP;
END $$;

-- ============================================
-- STEP 2: Drop ALL RLS policies
-- ============================================

DO $$ 
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', pol.policyname, pol.schemaname, pol.tablename);
        RAISE NOTICE 'Dropped policy: % on %.%', pol.policyname, pol.schemaname, pol.tablename;
    END LOOP;
END $$;

-- ============================================
-- STEP 3: Drop all triggers
-- ============================================

DO $$
DECLARE
    trg RECORD;
BEGIN
    FOR trg IN 
        SELECT trigger_name, event_object_table
        FROM information_schema.triggers
        WHERE trigger_schema = 'public'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.%I', trg.trigger_name, trg.event_object_table);
        RAISE NOTICE 'Dropped trigger: % on %', trg.trigger_name, trg.event_object_table;
    END LOOP;
END $$;

-- ============================================
-- STEP 4: Drop all functions (created by user)
-- ============================================

-- Drop sync functions if they exist
DROP FUNCTION IF EXISTS sync_user_to_driver() CASCADE;
DROP FUNCTION IF EXISTS sync_user_to_maintenance_personnel() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS handle_user_role_change() CASCADE;

-- ============================================
-- STEP 5: Drop all tables (order matters for foreign keys)
-- ============================================

-- Drop junction/child tables first
DROP TABLE IF EXISTS maintenance_record_parts CASCADE;
DROP TABLE IF EXISTS part_usage CASCADE;

-- Drop tables with foreign keys
DROP TABLE IF EXISTS trips CASCADE;
DROP TABLE IF EXISTS maintenance_tasks CASCADE;
DROP TABLE IF EXISTS maintenance_records CASCADE;
DROP TABLE IF EXISTS vehicle_assignments CASCADE;
DROP TABLE IF EXISTS fuel_logs CASCADE;

-- Drop main tables
DROP TABLE IF EXISTS parts CASCADE;
DROP TABLE IF EXISTS inventory_parts CASCADE;
DROP TABLE IF EXISTS vehicles CASCADE;
DROP TABLE IF EXISTS drivers CASCADE;
DROP TABLE IF EXISTS maintenance_personnel CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Drop any other tables that might exist
DROP TABLE IF EXISTS activities CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS settings CASCADE;
DROP TABLE IF EXISTS audit_logs CASCADE;

-- ============================================
-- STEP 6: Drop all views
-- ============================================

DROP VIEW IF EXISTS user_profiles CASCADE;
DROP VIEW IF EXISTS driver_dashboard CASCADE;
DROP VIEW IF EXISTS vehicle_status CASCADE;
DROP VIEW IF EXISTS maintenance_overview CASCADE;
DROP VIEW IF EXISTS fleet_summary CASCADE;

-- ============================================
-- STEP 7: Drop all custom types/enums
-- ============================================

DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS vehicle_status CASCADE;
DROP TYPE IF EXISTS vehicle_type CASCADE;
DROP TYPE IF EXISTS fuel_type CASCADE;
DROP TYPE IF EXISTS driver_status CASCADE;
DROP TYPE IF EXISTS trip_status CASCADE;
DROP TYPE IF EXISTS maintenance_status CASCADE;
DROP TYPE IF EXISTS maintenance_priority CASCADE;
DROP TYPE IF EXISTS part_category CASCADE;

-- ============================================
-- VERIFICATION: List remaining tables
-- ============================================

SELECT 
    'Remaining tables:' as info,
    tablename 
FROM pg_tables 
WHERE schemaname = 'public';

SELECT 
    'Remaining policies:' as info,
    policyname, tablename 
FROM pg_policies 
WHERE schemaname = 'public';

-- ============================================
-- DONE! Your database is now empty.
-- ============================================

-- Next steps:
-- 1. Run your new schema creation script
-- 2. Add RLS policies if needed (or keep them disabled for simplicity)
-- 3. Insert seed data if needed
