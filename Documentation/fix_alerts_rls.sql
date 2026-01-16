-- Fix RLS Policies for Alerts and Maintenance Alerts
-- This script enables insertion for authenticated users (Drivers)

-- 1. Alerts Table (General)
ALTER TABLE IF EXISTS public.alerts ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'alerts' AND policyname = 'Allow auth to insert alerts'
    ) THEN
        CREATE POLICY "Allow auth to insert alerts" ON public.alerts
        FOR INSERT TO authenticated WITH CHECK (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'alerts' AND policyname = 'Allow auth to select alerts'
    ) THEN
        CREATE POLICY "Allow auth to select alerts" ON public.alerts
        FOR SELECT TO authenticated USING (true);
    END IF;
END $$;

-- 2. Maintenance Alerts Table
ALTER TABLE IF EXISTS public.maintenance_alerts ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'maintenance_alerts' AND policyname = 'Allow auth to insert maintenance_alerts'
    ) THEN
        CREATE POLICY "Allow auth to insert maintenance_alerts" ON public.maintenance_alerts
        FOR INSERT TO authenticated WITH CHECK (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'maintenance_alerts' AND policyname = 'Allow auth to select maintenance_alerts'
    ) THEN
        CREATE POLICY "Allow auth to select maintenance_alerts" ON public.maintenance_alerts
        FOR SELECT TO authenticated USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'maintenance_alerts' AND policyname = 'Allow auth to update maintenance_alerts'
    ) THEN
        CREATE POLICY "Allow auth to update maintenance_alerts" ON public.maintenance_alerts
        FOR UPDATE TO authenticated USING (true);
    END IF;
END $$;
