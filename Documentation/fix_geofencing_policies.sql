-- =====================================================
-- FIX: Apply Missing RLS Policies
-- Run this script in the Supabase SQL Editor.
-- It adds the missing permissions that allow saving geofences.
-- =====================================================

-- 1. Geofences Policies
-- Allow authenticated users (Fleet Managers) to create, update, and delete zones
create policy "Authenticated Insert Geofences" on geofences for insert with check (auth.role() = 'authenticated');
create policy "Authenticated Update Geofences" on geofences for update using (auth.role() = 'authenticated');
create policy "Authenticated Delete Geofences" on geofences for delete using (auth.role() = 'authenticated');

-- 2. Geofence Routes Policies
-- Allow viewing routes and saving new ones
create policy "Public Read Routes" on geofence_routes for select using (true);
create policy "Authenticated Insert Routes" on geofence_routes for insert with check (auth.role() = 'authenticated');

-- 3. Geofence Violations Policies
-- Allow logging violations
create policy "Public Read Violations" on geofence_violations for select using (true);
create policy "Authenticated Insert Violations" on geofence_violations for insert with check (auth.role() = 'authenticated');
