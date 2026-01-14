# Map & Location Services - Developer Guide

**FleetTrack Location Infrastructure**  
**Version:** 2.0 (Simplified)  
**Last Updated:** January 13, 2026

---

## 📖 Overview

Universal, reusable location services for all FleetTrack modules. All components work with the existing `trips` table - **no separate geofences database needed**.

### What's Included

- ✅ Location management (GPS, permissions)
- ✅ Map display with user location
- ✅ Address ↔ coordinates conversion
- ✅ Route calculation with ETA
- ✅ Trip start/end monitoring (geofencing)
- ✅ Battery-optimized location updates
- ✅ iOS-compliant permission flow

---

## Quick Start

### 1. Display a Map

```swift
import SwiftUI

struct MyView: View {
    var body: some View {
        BasicMapView()
    }
}
```

### 2. Get Current Location

```swift
Task {
    let location = try await LocationService.shared.getCurrentLocation()
    print("📍 Lat: \(location.coordinate.latitude)")
}
```

### 3. Calculate Route

```swift
let route = try await RouteCalculationService.shared.calculateRoute(
    from: startCoordinate,
    to: endCoordinate
)
print("Distance: \(route.formattedDistance)")
print("Duration: \(route.formattedDuration)")
```

### 4. Monitor Trip Locations

```swift
// Start monitoring trip start/end
TripMonitoringManager.shared.startMonitoring(trip: activeTrip)

// Stop when trip ends
TripMonitoringManager.shared.stopMonitoring(trip: activeTrip)
```

---

## Architecture

```
FleetTrack/Core/
│
├── Services/
│   ├── LocationService.swift          → Location management
│   ├── GeocodingService.swift         → Address ↔ coordinates
│   ├── RouteCalculationService.swift  → Route calculation
│   ├── TripMonitoringManager.swift    → Monitor trip start/end
│   └── LocationError.swift            → Error types
│
├── ViewModels/
│   └── MapViewModel.swift             → Map state management
│
└── Views/
    └── BasicMapView.swift             → Map UI component
```

**Note:** Uses existing `trips` table (no separate geofences table needed)

---

## Core Services

### 1. LocationService

**Purpose:** Centralized location management

```swift
// Request permission
LocationService.shared.requestWhenInUseAuthorization()

// Get current location
let location = try await LocationService.shared.getCurrentLocation()

// Start continuous updates
LocationService.shared.configureForMode(.tracking)
LocationService.shared.startUpdatingLocation()

// Stop updates (save battery)
LocationService.shared.stopLocationUpdates()
```

---

### 2. GeocodingService

**Purpose:** Convert between addresses and coordinates

```swift
// Address → Coordinates
let coordinate = try await GeocodingService.shared.geocode(
    address: "Mumbai, Maharashtra"
)

// Coordinates → Address
let address = try await GeocodingService.shared.reverseGeocode(
    coordinate: CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777)
)
```

---

### 3. RouteCalculationService

**Purpose:** Calculate routes and navigation

```swift
let route = try await RouteCalculationService.shared.calculateRoute(
    from: startCoordinate,
    to: endCoordinate
)

print("Distance: \(route.distanceInKilometers) km")
print("Duration: \(route.formattedDuration)")
```

---

### 4. TripMonitoringManager

**Purpose:** Monitor trip start/end locations (geofencing)

**How it works:**
- Uses trip's `start_latitude/longitude` and `end_latitude/longitude`
- Creates 100m radius geofences around start/end
- Sends notifications on arrival/departure
- Automatically enforces 20-region iOS limit

```swift
// Start monitoring a trip
TripMonitoringManager.shared.startMonitoring(trip: trip)

// Observe events
TripMonitoringManager.shared.$recentEvents
    .sink { events in
        events.forEach { event in
            print("\(event.trip.id): \(event.event)")
        }
    }
    .store(in: &cancellables)

// Stop monitoring
TripMonitoringManager.shared.stopMonitoring(trip: trip)

// Stop all
TripMonitoringManager.shared.stopAllMonitoring()
```

**Events:**
- `.arrivedAtStart` - Driver arrived at pickup
- `.arrivedAtDestination` - Driver arrived at delivery
- `.leftStart` - Driver left pickup
- `.leftDestination` - Driver left delivery

---

## Integration Examples

### Example 1: Trip Planning with Map

```swift
struct TripPlanningView: View {
    @StateObject private var mapVM = MapViewModel()
    @State private var route: RouteResult?
    
    var body: some View {
        VStack {
            Map(coordinateRegion: $mapVM.region, showsUserLocation: true)
                .frame(height: 300)
            
            if let route = route {
                Text("Distance: \(route.formattedDistance)")
                Text("Duration: \(route.formattedDuration)")
            }
            
            Button("Calculate Route") {
                calculateRoute()
            }
        }
    }
    
    private func calculateRoute() {
        Task {
            route = try await RouteCalculationService.shared.calculateRoute(
                from: startCoordinate,
                to: endCoordinate
            )
        }
    }
}
```

---

### Example 2: Start Trip with Monitoring

```swift
struct StartTripView: View {
    let trip: Trip
    @StateObject private var tripMonitor = TripMonitoringManager.shared
    
    var body: some View {
        VStack {
            Text("Trip to \(trip.endAddress ?? "Destination")")
            
            Button("Start Trip") {
                startTrip()
            }
            
            Button("End Trip") {
                endTrip()
            }
        }
    }
    
    private func startTrip() {
        // Start location monitoring
        tripMonitor.startMonitoring(trip: trip)
        
        // Update trip status in database
        // trip.status = .ongoing
    }
    
    private func endTrip() {
        // Stop monitoring
        tripMonitor.stopMonitoring(trip: trip)
        
        // Update trip status
        // trip.status = .completed
    }
}
```

---

### Example 3: Driver Location Sharing

```swift
struct DriverLocationView: View {
    @StateObject private var locationService = LocationService.shared
    @State private var isSharing = false
    
    var body: some View {
        VStack {
            if let location = locationService.currentLocation {
                Text("📍 Lat: \(location.coordinate.latitude)")
                Text("📍 Long: \(location.coordinate.longitude)")
            }
            
            Toggle("Share Location", isOn: $isSharing)
                .onChange(of: isSharing) { sharing in
                    if sharing {
                        startSharing()
                    } else {
                        stopSharing()
                    }
                }
        }
    }
    
    private func startSharing() {
        locationService.configureForMode(.tracking)
        locationService.startUpdatingLocation()
    }
    
    private func stopSharing() {
        locationService.stopLocationUpdates()
    }
}
```

---

## Best Practices

### ✅ DO

1. **Stop location updates when not needed**
   ```swift
   .onDisappear {
       LocationService.shared.stopLocationUpdates()
   }
   ```

2. **Use appropriate accuracy mode**
   ```swift
   LocationService.shared.configureForMode(.tracking) // Active trip
   LocationService.shared.configureForMode(.background) // Background
   ```

3. **Monitor only active trips**
   ```swift
   // Start monitoring when trip starts
   TripMonitoringManager.shared.startMonitoring(trip: trip)
   
   // Stop when trip ends
   TripMonitoringManager.shared.stopMonitoring(trip: trip)
   ```

### ❌ DON'T

1. **Don't keep location updates running unnecessarily**
2. **Don't monitor more than 20 trips simultaneously** (iOS limit)
3. **Don't request Always permission without explanation**

---

## Database Integration

### No Separate Geofences Table Needed! ✅

The system uses the existing `trips` table:

```sql
-- trips table (already exists)
CREATE TABLE trips (
    id UUID PRIMARY KEY,
    vehicle_id UUID,
    driver_id UUID,
    start_address TEXT,
    start_latitude NUMERIC,  -- Used for start geofence
    start_longitude NUMERIC, -- Used for start geofence
    end_address TEXT,
    end_latitude NUMERIC,    -- Used for end geofence
    end_longitude NUMERIC,   -- Used for end geofence
    distance NUMERIC,
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    status trip_status,
    -- ... other fields
);
```

**That's it!** No additional tables needed.

---

## Testing Guide

### Prerequisites
⚠️ **Real Device Required** - Simulator has limited location support

### Test Checklist

#### Location Services
- [ ] Request When-In-Use permission
- [ ] Get current location
- [ ] Start/stop location updates
- [ ] Test different accuracy modes

#### Geocoding
- [ ] Forward geocode address
- [ ] Reverse geocode coordinates
- [ ] Test with invalid addresses

#### Route Calculation
- [ ] Calculate route
- [ ] Verify distance accuracy
- [ ] Verify ETA reasonableness

#### Trip Monitoring
- [ ] Start monitoring trip
- [ ] Walk to start location
- [ ] Verify arrival notification
- [ ] Walk to end location
- [ ] Verify arrival notification
- [ ] Stop monitoring

---

## Troubleshooting

### Location Not Updating
1. Check permission status
2. Verify location services enabled
3. Call `startUpdatingLocation()`

### Trip Monitoring Not Working
1. Verify Always permission granted
2. Check trip has valid coordinates
3. Ensure monitoring started
4. Test on real device (not simulator)

---

## API Reference

### LocationService
```swift
class LocationService {
    static let shared: LocationService
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    
    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()
    func startUpdatingLocation()
    func stopLocationUpdates()
    func getCurrentLocation() async throws -> CLLocation
}
```

### TripMonitoringManager
```swift
class TripMonitoringManager {
    static let shared: TripMonitoringManager
    
    @Published var monitoredTrips: [Trip]
    @Published var recentEvents: [(trip: Trip, event: TripMonitoringEvent, timestamp: Date)]
    
    func startMonitoring(trip: Trip)
    func stopMonitoring(trip: Trip)
    func stopAllMonitoring()
}
```

---

**Last Updated:** January 13, 2026  
**Version:** 2.0 (Simplified - No separate geofences table)
