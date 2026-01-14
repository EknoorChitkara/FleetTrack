//
//  LocationService.swift
//  FleetTrack
//
//  Centralized location management service
//  Phase 1: When-In-Use permission and basic location updates
//

import CoreLocation
import Combine

/// Location accuracy modes for different use cases
enum LocationAccuracyMode {
    case planning      // High accuracy for map display
    case tracking      // Balanced for trip monitoring
    case background    // Minimal for geofencing
    
    var clAccuracy: CLLocationAccuracy {
        switch self {
        case .planning: return kCLLocationAccuracyBest
        case .tracking: return kCLLocationAccuracyNearestTenMeters
        case .background: return kCLLocationAccuracyHundredMeters
        }
    }
    
    var distanceFilter: CLLocationDistance {
        switch self {
        case .planning: return kCLDistanceFilterNone
        case .tracking: return 50  // Update every 50 meters
        case .background: return 200  // Update every 200 meters
        }
    }
}

@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    // Published properties
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isUpdatingLocation: Bool = false
    
    // Private properties
    private let locationManager = CLLocationManager()
    private var currentMode: LocationAccuracyMode = .planning
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.showsBackgroundLocationIndicator = true  // iOS 11+
        locationManager.allowsBackgroundLocationUpdates = false  // Start disabled
        
        // Set initial status
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Permission Management
    
    /// Request When-In-Use permission (for map display)
    func requestWhenInUseAuthorization() {
        guard authorizationStatus == .notDetermined else {
            print("⚠️ Location permission already determined: \(authorizationStatus.description)")
            return
        }
        print("📍 Requesting When-In-Use location permission")
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Request Always permission (for trip tracking) - Phase 5
    /// NOTE: Only call this after user has When-In-Use permission
    func requestAlwaysAuthorization() {
        guard authorizationStatus == .authorizedWhenInUse else {
            print("⚠️ Cannot request Always without When-In-Use first. Current: \(authorizationStatus.description)")
            return
        }
        print("📍 Requesting Always location permission")
        locationManager.requestAlwaysAuthorization()
    }
    
    /// Check if location services are available
    var isLocationServicesEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }
    
    /// Check if we have any location permission
    var hasLocationPermission: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    // MARK: - Location Updates
    
    /// Configure location manager for specific mode
    func configureForMode(_ mode: LocationAccuracyMode) {
        currentMode = mode
        locationManager.desiredAccuracy = mode.clAccuracy
        locationManager.distanceFilter = mode.distanceFilter
        
        // Enable background updates only for tracking/background modes (Phase 5+)
        locationManager.allowsBackgroundLocationUpdates = false  // Phase 1: Always false
        
        print("📍 Configured for mode: \(mode) (accuracy: \(mode.clAccuracy)m, filter: \(mode.distanceFilter)m)")
    }
    
    /// Start continuous location updates
    func startUpdatingLocation() {
        guard isLocationServicesEnabled else {
            print("❌ Location services are disabled")
            return
        }
        
        guard hasLocationPermission else {
            print("❌ Location permission not granted. Current: \(authorizationStatus.description)")
            return
        }
        
        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
        print("📍 Started location updates")
    }
    
    /// Stop location updates
    func stopLocationUpdates() {
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        print("📍 Stopped location updates")
    }
    
    /// Get current location (one-time fetch)
    func getCurrentLocation() async throws -> CLLocation {
        guard isLocationServicesEnabled else {
            throw LocationError.unavailable
        }
        
        guard hasLocationPermission else {
            throw LocationError.permissionDenied
        }
        
        // If we already have a recent location (< 10 seconds old), return it
        if let location = currentLocation,
           location.timestamp.timeIntervalSinceNow > -10 {
            return location
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
            
            // Timeout after 10 seconds
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                if self.locationContinuation != nil {
                    self.locationContinuation = nil
                    continuation.resume(throwing: LocationError.timeout)
                }
            }
        }
    }
    
    // MARK: - Distance Calculation
    
    /// Calculate distance between two coordinates (in meters)
    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let newStatus = manager.authorizationStatus
            authorizationStatus = newStatus
            print("📍 Location authorization changed: \(newStatus.description)")
            
            // If permission was just granted, start updates if needed
            if hasLocationPermission && isUpdatingLocation {
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            currentLocation = location
            
            // Resolve any pending continuation
            if let continuation = locationContinuation {
                locationContinuation = nil
                continuation.resume(returning: location)
            }
            
            print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            print("❌ Location error: \(error.localizedDescription)")
            
            // Resolve any pending continuation with error
            if let continuation = locationContinuation {
                locationContinuation = nil
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - CLAuthorizationStatus Extension

extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }
}
