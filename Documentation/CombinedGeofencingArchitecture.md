# Combined Geofencing Architecture Plan

This document outlines the architecture for supporting two distinct types of geofencing in `FleetTrack`:
1.  **Route Deviation Monitoring** (Active, Polyline-based)
2.  **Stationary Zone Geofencing** (Passive, Circular Regions)

## 1. System Overview

Both systems run simultaneously but serve different purposes and use different iOS APIs for optimal performance.

| Feature | **Route Monitoring** | **Zone Monitoring** |
| :--- | :--- | :--- |
| **Purpose** | Detect if driver goes off-route | Detect entry/exit at Hubs/Depots |
| **Geometry** | Complex Polyline (Path) | Simple Circle (Radius) |
| **Technology** | `CLLocationManager` (Standard Updates) | `CLCircularRegion` (Region Monitoring) |
| **Frequency** | High (Real-time checks) | Low (System wakes app on entry/exit) |
| **Power Use** | High (while driving) | Low (Passive background) |
| **Manager** | `RouteMonitoringManager.swift` | `CircularGeofenceManager.swift` |

---

## 2. Route Monitoring (Active)

**Implementation:** `RouteMonitoringManager.swift`

*   **Trigger**: Starts when a Driver hits "Start Trip". Stops on "End Trip".
*   **Logic**:
    *   Subscribes to high-frequency GPS updates.
    *   On every location update, calculates the geometric distance to the nearest point on the Route Polyline.
    *   If `distance > corridor_radius` and `time > cooldown`, records a **Violation**.
*   **Backend Sync**: Syncs violations immediately to `geofence_violations` and `alerts`.

## 3. Zone Monitoring (Passive)

**Implementation:** `CircularGeofenceManager.swift`

*   **Trigger**: Can be initialized on App Launch or when fetching "Assigned Depots".
*   **Logic**:
    *   Registers `CLCircularRegion` with the OS.
    *   Does **NOT** require the app to be open. The OS monitors this even if the app is killed.
    *   On `didEnterRegion` or `didExitRegion`, the OS wakes the app in the background.
    *   Records an **Event** (ENTER/EXIT).
*   **Backend Sync**: Syncs events to `geofence_events`.

---

## 4. Integration Strategy

The **App Lifecycle** should manage these two services:

### A. Info.plist Permissions
Ensure `NSLocationAlwaysAndWhenInUseUsageDescription` is set. Zone monitoring requires "Always" to work reliably in the background.

### B. Deployment

**When to Start Route Monitoring:**
*   Only during an active `Trip`.
*   Call `RouteMonitoringManager.shared.startMonitoring(route:)` inside `TripMapView`.

**When to Start Zone Monitoring:**
*   Ideally at App Launch (`AppDelegate` or `App` struct).
*   Fetch relevant zones (e.g., Driver's home depot, Destination warehouse) from Supabase.
*   Call `CircularGeofenceManager.shared.startMonitoring(geofence:)`.

### C. Database Schema

1.  **`geofences`** (Stationary Zones)
    ```sql
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
    ```

2.  **`geofence_events`** (Zone Logs)
    ```sql
    create table geofence_events (
        id uuid primary key default gen_random_uuid(),
        geofence_id uuid references geofences(id),
        vehicle_id uuid, -- link to vehicle/driver
        event_type text, -- 'ENTER' or 'EXIT'
        timestamp timestamptz default now()
    );
    ```

3.  **`geofence_violations`** (Route Deviations)
    *   *Already defined in previous plan.*

---

## 5. Conflict Resolution

*   **Concurrent Usage**: It is perfectly fine to have both running.
*   **Example**: A driver is on a Trip (Route Monitoring Active) and enters a Depot (Zone Monitoring).
    *   `RouteMonitoringManager` sees the location is "On Route" (assuming the route ends at the depot).
    *   `CircularGeofenceManager` fires `didEnterRegion`.
    *   Both events are valid and recorded separately.

## 6. Limits & Best Practices

*   **Region Limit**: iOS limits apps to **20 monitored regions**.
    *   *Strategy*: If you have >20 depots, only monitor the 20 nearest to the driver's current location. Update this list significantly (e.g., every 50km).
*   **Accuracy**: Circular regions depend on cell tower/WiFi validation and may have latency (3-5 mins) for entry/exit events compared to the instant GPS tracking of the Route Monitor.
