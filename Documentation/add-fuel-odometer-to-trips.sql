-- Add fuel and odometer columns to trips table for manual logging
ALTER TABLE trips
ADD COLUMN IF NOT EXISTS start_odometer DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS end_odometer DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS start_fuel_level DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS end_fuel_level DOUBLE PRECISION;

-- Optional: Comments to describe the columns
COMMENT ON COLUMN trips.start_odometer IS 'Vehicle odometer reading at the start of the trip';
COMMENT ON COLUMN trips.end_odometer IS 'Vehicle odometer reading at the end of the trip';
COMMENT ON COLUMN trips.start_fuel_level IS 'Fuel level percentage (0-100) at the start of the trip';
COMMENT ON COLUMN trips.end_fuel_level IS 'Fuel level percentage (0-100) at the end of the trip';
