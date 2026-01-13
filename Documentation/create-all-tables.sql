-- ============================================
-- FleetTrack Database Schema
-- ============================================
-- Run this in Supabase SQL Editor after dropping all tables
-- Created: 2026-01-13
-- No RLS enabled (as requested)
-- ============================================

-- ============================================
-- STEP 1: Create Custom Types/Enums
-- ============================================

-- User roles
CREATE TYPE user_role AS ENUM ('Admin', 'Fleet Manager', 'Driver', 'Maintenance Personnel');

-- Vehicle related enums
CREATE TYPE vehicle_status AS ENUM ('Active', 'Inactive', 'Maintenance', 'Retired');
CREATE TYPE vehicle_type AS ENUM ('Truck', 'Van', 'Car', 'Bus', 'Motorcycle', 'Other');
CREATE TYPE fuel_type AS ENUM ('Petrol', 'Diesel', 'Electric', 'Hybrid', 'CNG', 'LPG');

-- Driver status
CREATE TYPE driver_status AS ENUM ('Available', 'On Trip', 'Off Duty', 'On Leave', 'Inactive');

-- Trip status
CREATE TYPE trip_status AS ENUM ('Scheduled', 'In Progress', 'Completed', 'Cancelled');

-- Maintenance related enums
CREATE TYPE maintenance_status AS ENUM ('Pending', 'In Progress', 'Completed', 'Cancelled');
CREATE TYPE maintenance_priority AS ENUM ('Low', 'Medium', 'High', 'Critical');

-- Part category
CREATE TYPE part_category AS ENUM ('Engine', 'Transmission', 'Brakes', 'Suspension', 'Electrical', 'Body Work', 'Tires', 'Fluids', 'Filters', 'Other');

-- ============================================
-- STEP 2: Create Core Tables
-- ============================================

-- Users table (linked to Supabase auth.users)
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'Driver',
    phone_number TEXT,
    profile_image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Drivers table
CREATE TABLE drivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    full_name TEXT,
    email TEXT,
    phone_number TEXT,
    address TEXT,
    license_number TEXT,
    driver_license_number TEXT,
    license_type TEXT,
    license_expiry_date DATE,
    status driver_status DEFAULT 'Available',
    rating DECIMAL(3,2) DEFAULT 0.00,
    safety_score DECIMAL(5,2) DEFAULT 100.00,
    total_trips INTEGER DEFAULT 0,
    total_distance_driven DECIMAL(10,2) DEFAULT 0.00,
    on_time_delivery_rate DECIMAL(5,2) DEFAULT 100.00,
    fuel_efficiency DECIMAL(5,2),
    current_vehicle_id UUID,
    current_trip_id UUID,
    certifications TEXT[],
    years_of_experience INTEGER DEFAULT 0,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    is_active BOOLEAN DEFAULT true,
    joined_date DATE DEFAULT CURRENT_DATE,
    last_active_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Maintenance Personnel table
CREATE TABLE maintenance_personnel (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    full_name TEXT NOT NULL,
    email TEXT,
    phone_number TEXT,
    specializations TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vehicles table
CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    registration_number TEXT NOT NULL UNIQUE,
    vehicle_type vehicle_type NOT NULL DEFAULT 'Truck',
    manufacturer TEXT,
    model TEXT,
    fuel_type fuel_type DEFAULT 'Diesel',
    capacity TEXT,
    vin TEXT,
    mileage DECIMAL(10,2) DEFAULT 0,
    registration_date DATE,
    insurance_status TEXT DEFAULT 'Valid',
    insurance_expiry DATE,
    last_service DATE,
    next_service_due DATE,
    status vehicle_status DEFAULT 'Active',
    assigned_driver_id UUID REFERENCES drivers(id) ON DELETE SET NULL,
    assigned_driver_name TEXT,
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    address TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add foreign key for current_vehicle_id in drivers
ALTER TABLE drivers 
ADD CONSTRAINT fk_drivers_current_vehicle 
FOREIGN KEY (current_vehicle_id) REFERENCES vehicles(id) ON DELETE SET NULL;

-- Trips table
CREATE TABLE trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    status trip_status DEFAULT 'Scheduled',
    start_address TEXT,
    end_address TEXT,
    start_latitude DECIMAL(10,7),
    start_longitude DECIMAL(10,7),
    end_latitude DECIMAL(10,7),
    end_longitude DECIMAL(10,7),
    distance DECIMAL(10,2),
    duration_minutes INTEGER,
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    purpose TEXT,
    notes TEXT,
    fuel_consumed DECIMAL(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add foreign key for current_trip_id in drivers
ALTER TABLE drivers 
ADD CONSTRAINT fk_drivers_current_trip 
FOREIGN KEY (current_trip_id) REFERENCES trips(id) ON DELETE SET NULL;

-- ============================================
-- STEP 3: Create Maintenance Tables
-- ============================================

-- Parts/Inventory table
CREATE TABLE parts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    part_number TEXT NOT NULL UNIQUE,
    category part_category DEFAULT 'Other',
    description TEXT,
    quantity_in_stock INTEGER DEFAULT 0,
    minimum_stock_level INTEGER DEFAULT 5,
    unit_price DECIMAL(10,2) DEFAULT 0.00,
    supplier_name TEXT,
    supplier_contact TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Maintenance Records table
CREATE TABLE maintenance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    performed_by UUID REFERENCES maintenance_personnel(id) ON DELETE SET NULL,
    maintenance_type TEXT NOT NULL,
    description TEXT,
    status maintenance_status DEFAULT 'Pending',
    priority maintenance_priority DEFAULT 'Medium',
    cost DECIMAL(10,2) DEFAULT 0.00,
    odometer_reading DECIMAL(10,2),
    scheduled_date DATE,
    completed_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Maintenance Tasks table
CREATE TABLE maintenance_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    maintenance_record_id UUID REFERENCES maintenance_records(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    assigned_to UUID REFERENCES maintenance_personnel(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    status maintenance_status DEFAULT 'Pending',
    priority maintenance_priority DEFAULT 'Medium',
    component TEXT,
    estimated_hours DECIMAL(5,2),
    actual_hours DECIMAL(5,2),
    parts_used JSONB DEFAULT '[]',
    due_date DATE,
    completed_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Junction table for maintenance records and parts used
CREATE TABLE maintenance_record_parts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    maintenance_record_id UUID NOT NULL REFERENCES maintenance_records(id) ON DELETE CASCADE,
    part_id UUID NOT NULL REFERENCES parts(id) ON DELETE CASCADE,
    quantity_used INTEGER NOT NULL DEFAULT 1,
    unit_cost DECIMAL(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 4: Create Activity/Logging Tables
-- ============================================

-- Fuel Logs table
CREATE TABLE fuel_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES drivers(id) ON DELETE SET NULL,
    fuel_type fuel_type,
    quantity DECIMAL(10,2) NOT NULL,
    cost DECIMAL(10,2),
    odometer_reading DECIMAL(10,2),
    station_name TEXT,
    location TEXT,
    fuel_date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activities table (for dashboard activity feed)
CREATE TABLE activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    icon TEXT DEFAULT 'info.circle',
    color TEXT DEFAULT 'blue',
    related_entity_type TEXT, -- 'vehicle', 'driver', 'trip', 'maintenance'
    related_entity_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 5: Create Indexes for Performance
-- ============================================

-- Users indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Drivers indexes
CREATE INDEX idx_drivers_user_id ON drivers(user_id);
CREATE INDEX idx_drivers_email ON drivers(email);
CREATE INDEX idx_drivers_status ON drivers(status);
CREATE INDEX idx_drivers_is_active ON drivers(is_active);

-- Vehicles indexes
CREATE INDEX idx_vehicles_registration ON vehicles(registration_number);
CREATE INDEX idx_vehicles_status ON vehicles(status);
CREATE INDEX idx_vehicles_assigned_driver ON vehicles(assigned_driver_id);

-- Trips indexes
CREATE INDEX idx_trips_vehicle ON trips(vehicle_id);
CREATE INDEX idx_trips_driver ON trips(driver_id);
CREATE INDEX idx_trips_status ON trips(status);
CREATE INDEX idx_trips_start_time ON trips(start_time);

-- Maintenance indexes
CREATE INDEX idx_maintenance_records_vehicle ON maintenance_records(vehicle_id);
CREATE INDEX idx_maintenance_tasks_vehicle ON maintenance_tasks(vehicle_id);
CREATE INDEX idx_maintenance_tasks_assigned ON maintenance_tasks(assigned_to);

-- Parts indexes
CREATE INDEX idx_parts_part_number ON parts(part_number);
CREATE INDEX idx_parts_category ON parts(category);

-- ============================================
-- STEP 6: Create Updated_at Trigger Function
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_drivers_updated_at BEFORE UPDATE ON drivers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON vehicles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_trips_updated_at BEFORE UPDATE ON trips FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_parts_updated_at BEFORE UPDATE ON parts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_maintenance_records_updated_at BEFORE UPDATE ON maintenance_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_maintenance_tasks_updated_at BEFORE UPDATE ON maintenance_tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_maintenance_personnel_updated_at BEFORE UPDATE ON maintenance_personnel FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STEP 7: Verify Tables Created
-- ============================================

SELECT 
    tablename as "Table Name",
    (SELECT COUNT(*) FROM pg_attribute WHERE attrelid = (schemaname || '.' || tablename)::regclass AND attnum > 0) as "Columns"
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- ============================================
-- DONE! Database schema created successfully.
-- ============================================

-- Tables created:
-- 1. users - User accounts (linked to auth.users)
-- 2. drivers - Driver profiles
-- 3. maintenance_personnel - Maintenance staff
-- 4. vehicles - Fleet vehicles
-- 5. trips - Trip records
-- 6. parts - Inventory/parts
-- 7. maintenance_records - Maintenance history
-- 8. maintenance_tasks - Maintenance work items
-- 9. maintenance_record_parts - Parts used in maintenance
-- 10. fuel_logs - Fuel consumption logs
-- 11. activities - Activity feed

-- No RLS is enabled (as requested)
-- To enable RLS later, use: ALTER TABLE tablename ENABLE ROW LEVEL SECURITY;
