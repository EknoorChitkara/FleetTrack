-- =====================================================
-- FleetTrack Geofencing Module - Supabase Schema
-- =====================================================

-- 1. Stationary Geofences (For Depots, Hubs)
create table geofences (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    latitude double precision not null,
    longitude double precision not null,
    radius_meters double precision not null,
    notify_on_entry boolean default true,
    notify_on_exit boolean default true,
    created_at timestamptz default now()
);

-- 2. Geofence Events (Logs for Stationary Zones)
create table geofence_events (
    id uuid primary key default gen_random_uuid(),
    geofence_id uuid references geofences(id),
    vehicle_id uuid, -- Optional link to vehicle/driver
    event_type text, -- 'ENTER' or 'EXIT'
    timestamp timestamptz default now()
);

-- 3. Route Violations (Active Deviation Logs)
create table geofence_routes (
    route_id uuid primary key, -- Likely matches trip_id
    start_latitude double precision not null,
    start_longitude double precision not null,
    end_latitude double precision not null,
    end_longitude double precision not null,
    encoded_polyline text not null, -- JSON string of coordinates
    corridor_radius_meters double precision not null,
    created_at timestamptz default now()
);

create table geofence_violations (
    id uuid primary key default gen_random_uuid(),
    route_id uuid references geofence_routes(route_id),
    driver_latitude double precision not null,
    driver_longitude double precision not null,
    distance_from_route double precision not null,
    timestamp timestamptz default now()
);

-- 4. Alerts (For Fleet Manager Dashboard)
create table alerts (
    id uuid primary key default gen_random_uuid(),
    trip_id uuid, -- Can reference trips(id)
    title text not null,
    message text not null,
    type text not null, -- 'geofence_violation', 'zone_entry', etc.
    timestamp timestamptz default now(),
    is_read boolean default false
);

-- RLS Policies (Example)
alter table geofences enable row level security;
create policy "Public Read Geofences" on geofences for select using (true);
create policy "Authenticated Insert Geofences" on geofences for insert with check (auth.role() = 'authenticated');
create policy "Authenticated Update Geofences" on geofences for update using (auth.role() = 'authenticated');
create policy "Authenticated Delete Geofences" on geofences for delete using (auth.role() = 'authenticated');

alter table geofence_events enable row level security;
create policy "Authenticated Insert Events" on geofence_events for insert with check (auth.role() = 'authenticated');

alter table alerts enable row level security;
create policy "Manager Read Alerts" on alerts for select using (true); -- Refine for manager role
create policy "Driver Insert Alerts" on alerts for insert with check (true);

alter table geofence_routes enable row level security;
create policy "Public Read Routes" on geofence_routes for select using (true);
create policy "Authenticated Insert Routes" on geofence_routes for insert with check (auth.role() = 'authenticated');

alter table geofence_violations enable row level security;
create policy "Public Read Violations" on geofence_violations for select using (true);
create policy "Authenticated Insert Violations" on geofence_violations for insert with check (auth.role() = 'authenticated');
