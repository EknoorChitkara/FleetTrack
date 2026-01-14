-- =====================================================
-- FleetTrack Vehicles Module - Supabase Schema
-- =====================================================
-- Execute this SQL in your Supabase SQL Editor
-- to create the required tables, indexes, and policies
-- =====================================================

-- =====================================================
-- Vehicles Table
-- =====================================================
CREATE TABLE IF NOT EXISTS vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Basic Info
    registration_number TEXT NOT NULL UNIQUE,
    vehicle_type vehicle_type NOT NULL,
    manufacturer TEXT,
    model TEXT,
    
    -- Technical Specs
    fuel_type fuel_type,
    capacity TEXT,
    vin TEXT,
    mileage NUMERIC DEFAULT 0,
    
    -- Dates
    registration_date DATE,
    insurance_expiry DATE,
    last_service DATE,
    next_service_due DATE,
    
    -- Status
    status vehicle_status DEFAULT 'active',
    insurance_status TEXT,
    
    -- Assignment
    assigned_driver_id UUID REFERENCES drivers(id) ON DELETE SET NULL,
    assigned_driver_name TEXT,
    
    -- Location (for tracking)
    latitude NUMERIC,
    longitude NUMERIC,
    address TEXT,
    
    -- Active Status
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- Custom Types (if not already created)
-- =====================================================

-- Vehicle Type Enum
DO $$ BEGIN
    CREATE TYPE vehicle_type AS ENUM (
        'sedan',
        'suv',
        'truck',
        'van',
        'pickup',
        'light_commercial',
        'heavy_commercial',
        'motorcycle',
        'other'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Fuel Type Enum
DO $$ BEGIN
    CREATE TYPE fuel_type AS ENUM (
        'petrol',
        'diesel',
        'electric',
        'hybrid',
        'cng',
        'lpg'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Vehicle Status Enum
DO $$ BEGIN
    CREATE TYPE vehicle_status AS ENUM (
        'active',
        'inactive',
        'maintenance',
        'retired',
        'in_transit'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- =====================================================
-- Indexes for Performance
-- =====================================================

-- Basic lookups
CREATE INDEX IF NOT EXISTS idx_vehicles_registration ON vehicles(registration_number);
CREATE INDEX IF NOT EXISTS idx_vehicles_type ON vehicles(vehicle_type);
CREATE INDEX IF NOT EXISTS idx_vehicles_status ON vehicles(status);
CREATE INDEX IF NOT EXISTS idx_vehicles_is_active ON vehicles(is_active);

-- Assignment tracking
CREATE INDEX IF NOT EXISTS idx_vehicles_assigned_driver ON vehicles(assigned_driver_id);

-- Maintenance tracking
CREATE INDEX IF NOT EXISTS idx_vehicles_next_service ON vehicles(next_service_due);
CREATE INDEX IF NOT EXISTS idx_vehicles_insurance_expiry ON vehicles(insurance_expiry);

-- Location tracking
CREATE INDEX IF NOT EXISTS idx_vehicles_location ON vehicles(latitude, longitude);

-- =====================================================
-- Trigger for Updated_At Timestamp
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_vehicles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
DROP TRIGGER IF EXISTS vehicles_updated_at_trigger ON vehicles;
CREATE TRIGGER vehicles_updated_at_trigger
    BEFORE UPDATE ON vehicles
    FOR EACH ROW
    EXECUTE FUNCTION update_vehicles_updated_at();

-- =====================================================
-- Views for Common Queries
-- =====================================================

-- View for active vehicles
CREATE OR REPLACE VIEW active_vehicles AS
SELECT *
FROM vehicles
WHERE is_active = true
ORDER BY registration_number;

-- View for available vehicles (not assigned)
CREATE OR REPLACE VIEW available_vehicles AS
SELECT *
FROM vehicles
WHERE is_active = true
  AND status = 'active'
  AND assigned_driver_id IS NULL
ORDER BY registration_number;

-- View for vehicles in maintenance
CREATE OR REPLACE VIEW vehicles_in_maintenance AS
SELECT *
FROM vehicles
WHERE status = 'maintenance'
ORDER BY next_service_due;

-- View for vehicles with drivers
CREATE OR REPLACE VIEW vehicles_with_drivers AS
SELECT 
    v.*,
    d.full_name as driver_full_name,
    d.email as driver_email,
    d.phone_number as driver_phone,
    d.status as driver_status
FROM vehicles v
LEFT JOIN drivers d ON v.assigned_driver_id = d.id
WHERE v.is_active = true
ORDER BY v.registration_number;

-- View for vehicles needing service
CREATE OR REPLACE VIEW vehicles_needing_service AS
SELECT 
    id,
    registration_number,
    vehicle_type,
    manufacturer,
    model,
    last_service,
    next_service_due,
    CASE 
        WHEN next_service_due < CURRENT_DATE THEN 'Overdue'
        WHEN next_service_due <= CURRENT_DATE + INTERVAL '7 days' THEN 'Due Soon'
        ELSE 'Scheduled'
    END as service_status
FROM vehicles
WHERE is_active = true
  AND next_service_due IS NOT NULL
ORDER BY next_service_due;

-- View for insurance expiry tracking
CREATE OR REPLACE VIEW vehicles_insurance_status AS
SELECT 
    id,
    registration_number,
    vehicle_type,
    insurance_status,
    insurance_expiry,
    CASE 
        WHEN insurance_expiry < CURRENT_DATE THEN 'Expired'
        WHEN insurance_expiry <= CURRENT_DATE + INTERVAL '30 days' THEN 'Expiring Soon'
        ELSE 'Valid'
    END as expiry_status,
    insurance_expiry - CURRENT_DATE as days_until_expiry
FROM vehicles
WHERE is_active = true
  AND insurance_expiry IS NOT NULL
ORDER BY insurance_expiry;

-- =====================================================
-- Row Level Security (RLS) Policies
-- =====================================================

-- Enable RLS on vehicles table
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read all vehicles
CREATE POLICY "Allow authenticated users to read vehicles"
ON vehicles FOR SELECT
TO authenticated
USING (true);

-- Policy: Allow authenticated users to insert vehicles
CREATE POLICY "Allow authenticated users to insert vehicles"
ON vehicles FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy: Allow authenticated users to update vehicles
CREATE POLICY "Allow authenticated users to update vehicles"
ON vehicles FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy: Allow authenticated users to delete vehicles
CREATE POLICY "Allow authenticated users to delete vehicles"
ON vehicles FOR DELETE
TO authenticated
USING (true);

-- =====================================================
-- Sample Data (Optional - for testing)
-- =====================================================

-- Uncomment to insert sample vehicles for testing

-- INSERT INTO vehicles (
--     registration_number, vehicle_type, manufacturer, model,
--     fuel_type, capacity, registration_date, status, is_active
-- ) VALUES 
--     ('MH-01-AB-1234', 'light_commercial', 'Tata', 'Ace', 
--      'diesel', '1 Ton', '2020-01-15', 'active', true),
--     ('MH-01-CD-5678', 'truck', 'Ashok Leyland', 'Dost', 
--      'diesel', '3 Ton', '2019-06-20', 'active', true),
--     ('MH-01-EF-9012', 'van', 'Mahindra', 'Supro', 
--      'diesel', '1.5 Ton', '2021-03-10', 'maintenance', true);

-- =====================================================
-- Verification Queries
-- =====================================================

-- Run these queries to verify the schema was created successfully

-- 1. Check vehicles table structure
SELECT 
    table_name, 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'vehicles'
ORDER BY ordinal_position;

-- 2. Check indexes
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'vehicles';

-- 3. Check RLS policies
SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'vehicles';

-- 4. Check views
SELECT 
    table_name,
    view_definition
FROM information_schema.views
WHERE table_name IN (
    'active_vehicles', 
    'available_vehicles', 
    'vehicles_in_maintenance',
    'vehicles_with_drivers',
    'vehicles_needing_service',
    'vehicles_insurance_status'
);

-- 5. Count vehicles
SELECT COUNT(*) as total_vehicles FROM vehicles;
SELECT COUNT(*) as active_vehicles FROM vehicles WHERE is_active = true;
SELECT COUNT(*) as available_vehicles FROM vehicles WHERE status = 'active' AND assigned_driver_id IS NULL;

-- =====================================================
-- Cleanup (Use with caution!)
-- =====================================================

-- Uncomment to drop the vehicles table and all related objects
-- WARNING: This will delete all vehicle data!

-- DROP VIEW IF EXISTS vehicles_insurance_status CASCADE;
-- DROP VIEW IF EXISTS vehicles_needing_service CASCADE;
-- DROP VIEW IF EXISTS vehicles_with_drivers CASCADE;
-- DROP VIEW IF EXISTS vehicles_in_maintenance CASCADE;
-- DROP VIEW IF EXISTS available_vehicles CASCADE;
-- DROP VIEW IF EXISTS active_vehicles CASCADE;
-- DROP TRIGGER IF EXISTS vehicles_updated_at_trigger ON vehicles;
-- DROP FUNCTION IF EXISTS update_vehicles_updated_at();
-- DROP TABLE IF EXISTS vehicles CASCADE;
-- DROP TYPE IF EXISTS vehicle_status CASCADE;
-- DROP TYPE IF EXISTS fuel_type CASCADE;
-- DROP TYPE IF EXISTS vehicle_type CASCADE;

-- =====================================================
-- End of Schema
-- =====================================================
