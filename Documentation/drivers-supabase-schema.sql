-- =====================================================
-- FleetTrack Drivers Module - Supabase Schema
-- =====================================================
-- Execute this SQL in your Supabase SQL Editor
-- to create the required tables, indexes, and policies
-- =====================================================

-- =====================================================
-- Drivers Table
-- =====================================================
CREATE TABLE IF NOT EXISTS drivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- User Reference
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Basic Info
    full_name TEXT,
    email TEXT,
    phone_number TEXT,
    address TEXT,
    
    -- License Info
    license_number TEXT,
    driver_license_number TEXT,
    license_type TEXT,
    license_expiry_date DATE,
    
    -- Status & Performance
    status driver_status DEFAULT 'available',
    rating NUMERIC,
    safety_score NUMERIC,
    
    -- Trip Metrics
    total_trips INT4 DEFAULT 0,
    total_distance_driven NUMERIC DEFAULT 0,
    on_time_delivery_rate NUMERIC,
    fuel_efficiency NUMERIC,
    
    -- Current Assignment
    current_vehicle_id UUID REFERENCES vehicles(id) ON DELETE SET NULL,
    current_trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
    
    -- Additional Info
    certifications TEXT,
    years_of_experience INT4,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    
    -- Active Status
    is_active BOOLEAN DEFAULT true,
    joined_date DATE,
    last_active_date TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- Custom Types (if not already created)
-- =====================================================

-- Driver Status Enum
DO $$ BEGIN
    CREATE TYPE driver_status AS ENUM (
        'available',
        'on_trip',
        'off_duty',
        'on_leave',
        'suspended'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- =====================================================
-- Indexes for Performance
-- =====================================================

-- Basic lookups
CREATE INDEX IF NOT EXISTS idx_drivers_user_id ON drivers(user_id);
CREATE INDEX IF NOT EXISTS idx_drivers_email ON drivers(email);
CREATE INDEX IF NOT EXISTS idx_drivers_status ON drivers(status);
CREATE INDEX IF NOT EXISTS idx_drivers_is_active ON drivers(is_active);

-- Performance metrics
CREATE INDEX IF NOT EXISTS idx_drivers_rating ON drivers(rating DESC);
CREATE INDEX IF NOT EXISTS idx_drivers_safety_score ON drivers(safety_score DESC);

-- Current assignments
CREATE INDEX IF NOT EXISTS idx_drivers_current_vehicle ON drivers(current_vehicle_id);
CREATE INDEX IF NOT EXISTS idx_drivers_current_trip ON drivers(current_trip_id);

-- License tracking
CREATE INDEX IF NOT EXISTS idx_drivers_license_expiry ON drivers(license_expiry_date);

-- =====================================================
-- Trigger for Updated_At Timestamp
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_drivers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
DROP TRIGGER IF EXISTS drivers_updated_at_trigger ON drivers;
CREATE TRIGGER drivers_updated_at_trigger
    BEFORE UPDATE ON drivers
    FOR EACH ROW
    EXECUTE FUNCTION update_drivers_updated_at();

-- =====================================================
-- Views for Common Queries
-- =====================================================

-- View for active drivers
CREATE OR REPLACE VIEW active_drivers AS
SELECT *
FROM drivers
WHERE is_active = true
ORDER BY full_name;

-- View for available drivers
CREATE OR REPLACE VIEW available_drivers AS
SELECT *
FROM drivers
WHERE is_active = true
  AND status = 'available'
ORDER BY rating DESC, safety_score DESC;

-- View for drivers on trip
CREATE OR REPLACE VIEW drivers_on_trip AS
SELECT 
    d.*,
    v.registration_number as vehicle_number,
    t.start_address,
    t.end_address,
    t.status as trip_status
FROM drivers d
LEFT JOIN vehicles v ON d.current_vehicle_id = v.id
LEFT JOIN trips t ON d.current_trip_id = t.id
WHERE d.status = 'on_trip'
ORDER BY d.full_name;

-- View for driver performance
CREATE OR REPLACE VIEW driver_performance AS
SELECT 
    id,
    full_name,
    email,
    status,
    rating,
    safety_score,
    total_trips,
    total_distance_driven,
    on_time_delivery_rate,
    fuel_efficiency,
    CASE 
        WHEN total_trips > 0 THEN total_distance_driven / total_trips
        ELSE 0
    END as avg_distance_per_trip
FROM drivers
WHERE is_active = true
ORDER BY rating DESC, safety_score DESC;

-- =====================================================
-- Row Level Security (RLS) Policies
-- =====================================================

-- Enable RLS on drivers table
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read all drivers
CREATE POLICY "Allow authenticated users to read drivers"
ON drivers FOR SELECT
TO authenticated
USING (true);

-- Policy: Allow authenticated users to insert drivers
CREATE POLICY "Allow authenticated users to insert drivers"
ON drivers FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy: Allow authenticated users to update drivers
CREATE POLICY "Allow authenticated users to update drivers"
ON drivers FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy: Allow authenticated users to delete drivers
CREATE POLICY "Allow authenticated users to delete drivers"
ON drivers FOR DELETE
TO authenticated
USING (true);

-- =====================================================
-- Sample Data (Optional - for testing)
-- =====================================================

-- Uncomment to insert sample drivers for testing

-- INSERT INTO drivers (
--     full_name, email, phone_number, address,
--     license_number, driver_license_number, license_type, license_expiry_date,
--     status, rating, safety_score,
--     years_of_experience, is_active
-- ) VALUES 
--     ('John Doe', 'john.doe@example.com', '+91-9876543210', '123 Main St, Mumbai',
--      'DL-2020-001', 'MH01-20200001', 'Commercial', '2025-12-31',
--      'available', 4.5, 95.0, 5, true),
--     ('Jane Smith', 'jane.smith@example.com', '+91-9876543211', '456 Oak Ave, Mumbai',
--      'DL-2021-002', 'MH01-20210002', 'Commercial', '2026-06-30',
--      'available', 4.8, 98.0, 8, true),
--     ('Mike Johnson', 'mike.j@example.com', '+91-9876543212', '789 Pine Rd, Mumbai',
--      'DL-2019-003', 'MH01-20190003', 'Commercial', '2024-12-31',
--      'on_trip', 4.2, 92.0, 3, true);

-- =====================================================
-- Verification Queries
-- =====================================================

-- Run these queries to verify the schema was created successfully

-- 1. Check drivers table structure
SELECT 
    table_name, 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'drivers'
ORDER BY ordinal_position;

-- 2. Check indexes
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'drivers';

-- 3. Check RLS policies
SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'drivers';

-- 4. Check views
SELECT 
    table_name,
    view_definition
FROM information_schema.views
WHERE table_name IN ('active_drivers', 'available_drivers', 'drivers_on_trip', 'driver_performance');

-- 5. Count drivers
SELECT COUNT(*) as total_drivers FROM drivers;
SELECT COUNT(*) as active_drivers FROM drivers WHERE is_active = true;
SELECT COUNT(*) as available_drivers FROM drivers WHERE status = 'available';

-- =====================================================
-- Cleanup (Use with caution!)
-- =====================================================

-- Uncomment to drop the drivers table and all related objects
-- WARNING: This will delete all driver data!

-- DROP VIEW IF EXISTS driver_performance CASCADE;
-- DROP VIEW IF EXISTS drivers_on_trip CASCADE;
-- DROP VIEW IF EXISTS available_drivers CASCADE;
-- DROP VIEW IF EXISTS active_drivers CASCADE;
-- DROP TRIGGER IF EXISTS drivers_updated_at_trigger ON drivers;
-- DROP FUNCTION IF EXISTS update_drivers_updated_at();
-- DROP TABLE IF EXISTS drivers CASCADE;
-- DROP TYPE IF EXISTS driver_status CASCADE;

-- =====================================================
-- End of Schema
-- =====================================================
