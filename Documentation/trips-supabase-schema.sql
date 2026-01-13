-- =====================================================
-- FleetTrack Trips Module - Supabase Schema
-- =====================================================
-- Execute this SQL in your Supabase SQL Editor
-- to create the required tables, indexes, and policies
-- =====================================================

-- =====================================================
-- Trips Table
-- =====================================================
CREATE TABLE IF NOT EXISTS trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Foreign Keys
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE RESTRICT,
    driver_id UUID REFERENCES drivers(id) ON DELETE SET NULL,
    
    -- Trip Status
    status TEXT NOT NULL DEFAULT 'Scheduled' 
        CHECK (status IN ('Scheduled', 'Ongoing', 'Completed', 'Cancelled')),
    
    -- Start Location (GPS + Address)
    start_lat DOUBLE PRECISION,
    start_long DOUBLE PRECISION,
    start_address TEXT,
    
    -- End Location (GPS + Address)
    end_lat DOUBLE PRECISION,
    end_long DOUBLE PRECISION,
    end_address TEXT,
    
    -- Timing
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    
    -- Metrics
    distance NUMERIC,  -- Distance in kilometers
    
    -- Metadata
    purpose TEXT,
    notes TEXT,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_distance CHECK (distance IS NULL OR distance >= 0),
    CONSTRAINT valid_times CHECK (end_time IS NULL OR end_time >= start_time)
);

-- =====================================================
-- Indexes for Performance
-- =====================================================

-- Index on vehicle_id for filtering trips by vehicle
CREATE INDEX IF NOT EXISTS idx_trips_vehicle_id 
    ON trips(vehicle_id);

-- Index on driver_id for filtering trips by driver
CREATE INDEX IF NOT EXISTS idx_trips_driver_id 
    ON trips(driver_id);

-- Index on status for filtering by trip status
CREATE INDEX IF NOT EXISTS idx_trips_status 
    ON trips(status);

-- Index on start_time for chronological sorting
CREATE INDEX IF NOT EXISTS idx_trips_start_time 
    ON trips(start_time DESC);

-- Composite index for vehicle + status queries
CREATE INDEX IF NOT EXISTS idx_trips_vehicle_status 
    ON trips(vehicle_id, status);

-- Composite index for driver + status queries
CREATE INDEX IF NOT EXISTS idx_trips_driver_status 
    ON trips(driver_id, status);

-- Index on created_by for filtering trips by creator
CREATE INDEX IF NOT EXISTS idx_trips_created_by 
    ON trips(created_by);

-- =====================================================
-- Trigger for Updated_At Timestamp
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_trips_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
DROP TRIGGER IF EXISTS trips_updated_at_trigger ON trips;
CREATE TRIGGER trips_updated_at_trigger
    BEFORE UPDATE ON trips
    FOR EACH ROW
    EXECUTE FUNCTION update_trips_updated_at();

-- =====================================================
-- Views for Common Queries
-- =====================================================

-- View for active trips (scheduled or ongoing)
CREATE OR REPLACE VIEW active_trips AS
SELECT 
    t.*,
    v.registration_number as vehicle_name,
    d.full_name as driver_name
FROM trips t
LEFT JOIN vehicles v ON t.vehicle_id = v.id
LEFT JOIN drivers d ON t.driver_id = d.id
WHERE t.status IN ('Scheduled', 'Ongoing')
ORDER BY t.start_time ASC;

-- View for trip statistics
CREATE OR REPLACE VIEW trip_statistics AS
SELECT 
    COUNT(*) FILTER (WHERE status = 'Scheduled') as scheduled_count,
    COUNT(*) FILTER (WHERE status = 'Ongoing') as ongoing_count,
    COUNT(*) FILTER (WHERE status = 'Completed') as completed_count,
    COUNT(*) FILTER (WHERE status = 'Cancelled') as cancelled_count,
    COUNT(*) as total_trips,
    SUM(distance) FILTER (WHERE status = 'Completed') as total_distance_completed,
    AVG(distance) FILTER (WHERE status = 'Completed') as avg_trip_distance,
    AVG(
        EXTRACT(EPOCH FROM (end_time - start_time)) / 3600
    ) FILTER (WHERE status = 'Completed' AND end_time IS NOT NULL) as avg_trip_duration_hours
FROM trips;

-- =====================================================
-- Row Level Security (RLS) Policies
-- =====================================================

-- Enable RLS on trips table
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read all trips
CREATE POLICY "Allow authenticated users to read trips"
ON trips FOR SELECT
TO authenticated
USING (true);

-- Policy: Allow authenticated users to insert trips
-- (In production, you might want to restrict this to Fleet Managers only)
CREATE POLICY "Allow authenticated users to insert trips"
ON trips FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy: Allow authenticated users to update trips
-- (In production, you might want to restrict updates based on role or ownership)
CREATE POLICY "Allow authenticated users to update trips"
ON trips FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy: Allow authenticated users to delete trips
-- (In production, you might want to restrict this to Fleet Managers only)
CREATE POLICY "Allow authenticated users to delete trips"
ON trips FOR DELETE
TO authenticated
USING (true);

-- =====================================================
-- Optional: Role-Based Policies (Commented Out)
-- =====================================================
-- Uncomment these if you want stricter role-based access control

-- -- Only Fleet Managers can create trips
-- CREATE POLICY "Only fleet managers can create trips"
-- ON trips FOR INSERT
-- TO authenticated
-- WITH CHECK (
--     EXISTS (
--         SELECT 1 FROM users 
--         WHERE users.id = auth.uid() 
--         AND users.role = 'Fleet Manager'
--     )
-- );

-- -- Drivers can only view their assigned trips
-- CREATE POLICY "Drivers can view their assigned trips"
-- ON trips FOR SELECT
-- TO authenticated
-- USING (
--     EXISTS (
--         SELECT 1 FROM users 
--         WHERE users.id = auth.uid() 
--         AND (users.role = 'Fleet Manager' OR trips.driver_id = auth.uid())
--     )
-- );

-- =====================================================
-- Verification Queries
-- =====================================================

-- Run these queries to verify the table was created successfully

-- 1. Check table structure
SELECT 
    table_name, 
    column_name, 
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'trips'
ORDER BY ordinal_position;

-- 2. Check indexes
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'trips';

-- 3. Check constraints
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'trips'::regclass;

-- 4. Check RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'trips';

-- 5. Check triggers
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'trips';

-- =====================================================
-- Sample Data (Optional - for testing)
-- =====================================================

-- Uncomment to insert sample trips for testing
-- Note: Replace UUIDs with actual IDs from your vehicles and drivers tables

-- INSERT INTO trips (
--     vehicle_id,
--     driver_id,
--     status,
--     start_address,
--     end_address,
--     start_lat,
--     start_long,
--     end_lat,
--     end_long,
--     start_time,
--     distance,
--     purpose,
--     notes
-- ) VALUES (
--     'your-vehicle-uuid-here',
--     'your-driver-uuid-here',
--     'Scheduled',
--     'Mumbai, Maharashtra',
--     'Pune, Maharashtra',
--     19.0760,
--     72.8777,
--     18.5204,
--     73.8567,
--     NOW() + INTERVAL '2 hours',
--     148.5,
--     'Urgent Delivery',
--     'Handle with care'
-- );

-- =====================================================
-- Cleanup (Use with caution!)
-- =====================================================

-- Uncomment to drop the trips table and all related objects
-- WARNING: This will delete all trip data!

-- DROP VIEW IF EXISTS trip_statistics CASCADE;
-- DROP VIEW IF EXISTS active_trips CASCADE;
-- DROP TRIGGER IF EXISTS trips_updated_at_trigger ON trips;
-- DROP FUNCTION IF EXISTS update_trips_updated_at();
-- DROP TABLE IF EXISTS trips CASCADE;

-- =====================================================
-- End of Schema
-- =====================================================
