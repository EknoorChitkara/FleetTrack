# Map & Geofencing - Quick Reference

**Quick copy-paste examples for common tasks**

---

## 🗺️ Display Map

```swift
import SwiftUI

struct MyView: View {
    var body: some View {
        BasicMapView()
    }
}
```

---

## 📍 Get Current Location

```swift
Task {
    let location = try await LocationService.shared.getCurrentLocation()
    print("Lat: \(location.coordinate.latitude)")
    print("Long: \(location.coordinate.longitude)")
}
```

---

## 🔍 Address → Coordinates

```swift
let coordinate = try await GeocodingService.shared.geocode(
    address: "Mumbai, Maharashtra, India"
)
```

---

## 🔍 Coordinates → Address

```swift
let address = try await GeocodingService.shared.reverseGeocode(
    coordinate: CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777)
)
```

---

## 🛣️ Calculate Route

```swift
let route = try await RouteCalculationService.shared.calculateRoute(
    from: startCoordinate,
    to: endCoordinate
)
print("Distance: \(route.formattedDistance)")
print("Duration: \(route.formattedDuration)")
```

---

## 🎯 Monitor Geofences

```swift
// Load geofences
GeofenceManager.shared.loadGeofences(geofences)

// Start monitoring nearest 20
GeofenceManager.shared.updateMonitoredRegions(
    strategy: .proximity,
    currentLocation: currentLocation
)

// Stop monitoring
GeofenceManager.shared.stopAllMonitoring()
```

---

## 🔋 Battery Optimization

```swift
// Map display (high accuracy)
LocationService.shared.configureForMode(.planning)

// Active trip (balanced)
LocationService.shared.configureForMode(.tracking)

// Background (low power)
LocationService.shared.configureForMode(.background)

// Always stop when done
.onDisappear {
    LocationService.shared.stopLocationUpdates()
}
```

---

## 🔐 Permissions

```swift
// Phase 1: When-In-Use (for map display)
LocationService.shared.requestWhenInUseAuthorization()

// Phase 2: Always (for trip tracking - show explanation first!)
LocationService.shared.requestAlwaysAuthorization()
```

---

## 📊 Observe Updates

```swift
import Combine

var cancellables = Set<AnyCancellable>()

// Observe location
LocationService.shared.$currentLocation
    .sink { location in
        print("Location: \(location)")
    }
    .store(in: &cancellables)

// Observe geofence events
GeofenceManager.shared.$geofenceEvents
    .sink { events in
        print("Events: \(events)")
    }
    .store(in: &cancellables)
```

---

## 🏗️ Custom Map View

```swift
struct CustomMapView: View {
    @StateObject private var mapVM = MapViewModel()
    
    var body: some View {
        Map(coordinateRegion: $mapVM.region, showsUserLocation: true)
            .onAppear {
                mapVM.requestLocationAndCenter()
                mapVM.startLocationUpdates()
            }
            .onDisappear {
                mapVM.stopLocationUpdates()
            }
    }
}
```

---

## ⚠️ Error Handling

```swift
do {
    let location = try await LocationService.shared.getCurrentLocation()
} catch LocationError.permissionDenied {
    print("Permission denied - show settings prompt")
} catch LocationError.timeout {
    print("Timeout - retry")
} catch {
    print("Error: \(error.localizedDescription)")
}
```

---

## 📱 Full Example: Trip Planning

```swift
struct TripPlanView: View {
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
                Task {
                    route = try await RouteCalculationService.shared.calculateRoute(
                        from: startCoordinate,
                        to: endCoordinate
                    )
                }
            }
        }
        .onAppear {
            mapVM.requestLocationAndCenter()
        }
    }
}
```

---

**See [MAP_AND_GEOFENCING_README.md](MAP_AND_GEOFENCING_README.md) for full documentation**
