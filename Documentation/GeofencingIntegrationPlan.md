# Geofencing Integration Plan

## Overview
We have implemented the core services for Geofencing Route Monitoring:
1. **`GeofencingModels.swift`**: Models for Route and Violation.
2. **`RouteService.swift`**: Fetches routes from MapKit and creates `GeofenceRoute`.
3. **`RouteMonitoringManager.swift`**: Handles continuous location tracking, geometric distance calculation, corridor checks, and violation reporting to Supabase.

## integration Steps

To fully integrate this into the `FleetTrack` app, follow these steps:

### 1. Update `TripMapView` to Start Monitoring
In `TripMapView.swift`, specifically inside the `startDelivery()` function (or where the "Start Trip" action occurs):

```swift
private func startDelivery() {
    Task {
        // 1. Existing status update
        try? await supabase.from("trips")
            .update(["status": "In Progress", ...])
            .eq("id", value: trip.id).execute()
        
        // 2. NEW: Fetch and Start Geofencing
        if let startLat = trip.startLat, let startLong = trip.startLong,
           let endLat = trip.endLat, let endLong = trip.endLong {
            
            let start = CLLocationCoordinate2D(latitude: startLat, longitude: startLong)
            let end = CLLocationCoordinate2D(latitude: endLat, longitude: endLong)
            
            do {
                // Fetch route from MapKit
                let mkRoute = try await RouteService.shared.fetchRoute(from: start, to: end)
                
                // Create Geofence Model (e.g., 100m corridor)
                let geofenceRoute = try RouteService.shared.createGeofenceRoute(
                    from: mkRoute,
                    routeId: trip.id,
                    start: start,
                    end: end,
                    corridorRadius: 100
                )
                
                // Start Monitoring
                RouteMonitoringManager.shared.startMonitoring(route: geofenceRoute)
                
            } catch {
                print("Failed to start route monitoring: \(error)")
            }
        }
        
        await MainActor.run { dismiss() }
    }
}
```

### 2. Stop Monitoring on Completion
In `TripMapView.completeTrip()`:

```swift
private func completeTrip() {
    // ... existing update ...
    RouteMonitoringManager.shared.stopMonitoring()
    // ...
}
```

### 3. Visualizing Violations (Step 8)
To visualize the route color changing based on the corridor status:

1.  **Observe `RouteMonitoringManager`**:
    Add `@StateObject var routeMonitor = RouteMonitoringManager.shared` to `TripMapView`.

2.  **Pass State to `LiveTripMap`**:
    Pass `routeMonitor.isOffRoute` to `LiveTripMap`.

3.  **Update `LiveTripMap` Coordinator**:
    In `mapView(_:rendererFor:)`, change the stroke color dynamically.
    
    *Note*: `MKMapView` does not automatically refresh overlays when state changes. You must trigger a refresh.
    
    **Option A: Re-add Overlay**
    When `isOffRoute` changes (detected via `updateUIView`), remove the old polyline and add it again. The delegate will then re-create the renderer with the new color (Red for off-route, Green/Blue for on-route).
    
    **Option B: Custom Renderer**
    Create a custom `MKPolylineRenderer` subclass that can update its `strokeColor` property without re-adding the overlay, and trigger `setNeedsDisplay()`.

### 4. Database Schema
Ensure the following tables exist in Supabase:
- `geofence_routes`: Columns matching `GeofenceRoute` (jsonb for polyline recommended or text).
- `geofence_violations`: Columns matching `GeofenceViolation`.
- `alerts`: Table for Fleet Manager notifications.
    ```sql
    create table alerts (
        id uuid primary key default gen_random_uuid(),
        trip_id uuid references trips(id),
        title text not null,
        message text not null,
        type text not null, -- 'geofence_violation'
        timestamp timestamptz default now(),
        is_read boolean default false
    );
    ```

### 5. Backend RPC (Optional)
For efficiency, consider an RPC function to save the route if the polyline string is very large, although direct Insert is usually fine for reasonable routes.
