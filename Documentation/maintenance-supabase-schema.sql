-- =====================================================
-- FleetTrack Maintenance Module - Supabase Schema
-- =====================================================
-- Execute this SQL in your Supabase SQL Editor
-- to create the required tables and views
-- =====================================================

-- =====================================================
-- Maintenance Tasks Table
-- =====================================================
CREATE TABLE IF NOT EXISTS maintenance_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vehicle_registration_number TEXT NOT NULL,
    priority TEXT NOT NULL CHECK (priority IN ('High', 'Medium', 'Low')),
    component TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Pending',
    due_date TIMESTAMPTZ NOT NULL,
    completed_date TIMESTAMPTZ,
    parts_used JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- Indexes for Performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_status 
    ON maintenance_tasks(status);

CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_priority 
    ON maintenance_tasks(priority);

CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_due_date 
    ON maintenance_tasks(due_date);

CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_vehicle 
    ON maintenance_tasks(vehicle_registration_number);

-- =====================================================
-- Maintenance Summary View (for statistics)
-- =====================================================
CREATE OR REPLACE VIEW maintenance_summary AS
SELECT 
    COUNT(*) FILTER (
        WHERE status = 'Completed' 
        AND completed_date >= DATE_TRUNC('month', NOW())
    ) AS completed_tasks_this_month,
    AVG(
        EXTRACT(EPOCH FROM (completed_date - created_at)) / 3600
    ) FILTER (
        WHERE status = 'Completed'
    ) AS average_completion_time_hours
FROM maintenance_tasks;

-- =====================================================
-- Row Level Security (RLS) Policies
-- =====================================================
ALTER TABLE maintenance_tasks ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read all maintenance tasks
CREATE POLICY "Allow authenticated users to read maintenance tasks"
ON maintenance_tasks FOR SELECT
TO authenticated
USING (true);

-- Allow authenticated users to insert maintenance tasks
CREATE POLICY "Allow authenticated users to insert maintenance tasks"
ON maintenance_tasks FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow authenticated users to update maintenance tasks
CREATE POLICY "Allow authenticated users to update maintenance tasks"
ON maintenance_tasks FOR UPDATE
TO authenticated
USING (true);

-- Allow authenticated users to delete maintenance tasks
CREATE POLICY "Allow authenticated users to delete maintenance tasks"
ON maintenance_tasks FOR DELETE
TO authenticated
USING (true);

-- =====================================================
-- Verification Query
-- =====================================================
-- Run this to verify the table was created successfully
SELECT 
    table_name, 
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_name = 'maintenance_tasks'
ORDER BY ordinal_position;
