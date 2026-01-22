-- Migration: Add Fuel Tracking and Efficiency Features

-- 1. Create fuel_refills table
CREATE TABLE IF NOT EXISTS fuel_refills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID REFERENCES trips(id) ON DELETE CASCADE,
    vehicle_id UUID REFERENCES vehicles(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES auth.users(id),
    fuel_added_liters DOUBLE PRECISION NOT NULL,
    fuel_cost DOUBLE PRECISION,
    odometer_reading DOUBLE PRECISION,
    fuel_gauge_photo_url TEXT,
    receipt_photo_url TEXT,
    location_latitude DOUBLE PRECISION,
    location_longitude DOUBLE PRECISION,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Add columns to trips table for photos and tracking
ALTER TABLE trips
ADD COLUMN IF NOT EXISTS start_fuel_gauge_photo_url TEXT,
ADD COLUMN IF NOT EXISTS end_fuel_gauge_photo_url TEXT,
ADD COLUMN IF NOT EXISTS start_odometer_photo_url TEXT,
ADD COLUMN IF NOT EXISTS end_odometer_photo_url TEXT,
ADD COLUMN IF NOT EXISTS actual_route_index INTEGER; -- Index of route selected by driver

-- 3. Add standard efficiency to vehicles table for baseline comparison
ALTER TABLE vehicles
ADD COLUMN IF NOT EXISTS standard_fuel_efficiency DOUBLE PRECISION; -- km per liter

-- Comments for documentation
COMMENT ON TABLE fuel_refills IS 'Records of fuel refills during trips';
COMMENT ON COLUMN trips.actual_route_index IS 'Index of the route selected by the driver at the start of the trip';
COMMENT ON COLUMN vehicles.standard_fuel_efficiency IS 'Average fuel efficiency (km/L) for this vehicle based on past performance';
