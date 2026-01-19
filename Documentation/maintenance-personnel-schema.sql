-- =====================================================
-- FleetTrack Maintenance Personnel - Supabase Schema
-- =====================================================
-- Execute this SQL in your Supabase SQL Editor
-- to create the maintenance_personnel table
-- =====================================================

-- =====================================================
-- Maintenance Personnel Table
-- =====================================================
CREATE TABLE IF NOT EXISTS maintenance_personnel (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT UNIQUE,
    phone_number TEXT,
    specializations TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- Indexes for Performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_maintenance_personnel_user_id 
    ON maintenance_personnel(user_id);

CREATE INDEX IF NOT EXISTS idx_maintenance_personnel_email 
    ON maintenance_personnel(email);

CREATE INDEX IF NOT EXISTS idx_maintenance_personnel_is_active 
    ON maintenance_personnel(is_active);

-- =====================================================
-- Row Level Security (RLS) Policies
-- =====================================================
ALTER TABLE maintenance_personnel ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read maintenance personnel
CREATE POLICY "Allow authenticated users to read maintenance personnel"
ON maintenance_personnel FOR SELECT
TO authenticated
USING (true);

-- Allow authenticated users to insert maintenance personnel
CREATE POLICY "Allow authenticated users to insert maintenance personnel"
ON maintenance_personnel FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow authenticated users to update maintenance personnel
CREATE POLICY "Allow authenticated users to update maintenance personnel"
ON maintenance_personnel FOR UPDATE
TO authenticated
USING (true);

-- Allow authenticated users to delete maintenance personnel
CREATE POLICY "Allow authenticated users to delete maintenance personnel"
ON maintenance_personnel FOR DELETE
TO authenticated
USING (true);

-- =====================================================
-- Verification Query
-- =====================================================
-- Run this to verify the table was created successfully
SELECT 
    table_name, 
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'maintenance_personnel'
ORDER BY ordinal_position;
