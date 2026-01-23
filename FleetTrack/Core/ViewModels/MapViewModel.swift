//
//  MapViewModel.swift
//  FleetTrack
//
//  Reusable ViewModel for map-based features
//  Phase 1: Basic map display with current location
//

import SwiftUI
import MapKit
import Combine

@MainActor
class MapViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    /// Current map region (Legacy support)
    @Published var region: MKCoordinateRegion
    
    /// Modern map position (iOS 17+)
    @Published var position: MapCameraPosition
    
    /// Current user location
    @Published var currentLocation: CLLocation?
    
    /// Loading state
    @Published var isLoadingLocation: Bool = false
    
    /// Error message
    @Published var errorMessage: String?
    
    // MARK: - Services
    
    private let locationService = LocationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    override init() {
        // Default region (will be updated to user's location)
        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777), // Mumbai
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        self.region = initialRegion
        self.position = .region(initialRegion)
        
        super.init()
        
        // Observe location updates from LocationService
        locationService.$currentLocation
            .sink { [weak self] location in
                self?.currentLocation = location
            }
            .store(in: &cancellables)
        
        // Observe authorization status
        locationService.$authorizationStatus
            .sink { [weak self] status in
                self?.handleAuthorizationChange(status)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Location Management
    
    /// Request location permission and center on user location
    func requestLocationAndCenter() {
        // Check if location services are enabled
        guard locationService.isLocationServicesEnabled else {
            errorMessage = "Location services are disabled. Please enable them in Settings."
            return
        }
        
        let status = locationService.authorizationStatus
        
        switch status {
        case .notDetermined:
            // Request When-In-Use permission
            locationService.requestWhenInUseAuthorization()
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Already have permission, get location
            getCurrentLocationAndCenter()
            
        case .denied:
            errorMessage = "Location access denied. Please enable it in Settings > FleetTrack > Location."
            
        case .restricted:
            errorMessage = "Location access is restricted on this device."
            
        @unknown default:
            errorMessage = "Unknown location authorization status."
        }
    }
    
    /// Get current location and center map
    func getCurrentLocationAndCenter() {
        isLoadingLocation = true
        errorMessage = nil
        
        Task {
            do {
                let location = try await locationService.getCurrentLocation()
                
                // Center map on user location
                withAnimation {
                    let newRegion = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                    region = newRegion
                    position = .region(newRegion)
                }
                
                isLoadingLocation = false
            } catch {
                errorMessage = "Failed to get location: \(error.localizedDescription)"
                isLoadingLocation = false
            }
        }
    }
    
    /// Center map on current location (if available)
    func centerOnCurrentLocation() {
        guard let location = currentLocation else {
            // No location yet, request it
            getCurrentLocationAndCenter()
            return
        }
        
        withAnimation {
            let newRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            region = newRegion
            position = .region(newRegion)
        }
    }
    
    /// Start continuous location updates
    func startLocationUpdates() {
        locationService.configureForMode(.planning)
        locationService.startUpdatingLocation()
    }
    
    /// Stop location updates
    func stopLocationUpdates() {
        locationService.stopLocationUpdates()
    }
    
    // MARK: - Private Methods
    
    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission granted, get location
            getCurrentLocationAndCenter()
            
        case .denied:
            errorMessage = "Location access denied."
            
        case .restricted:
            errorMessage = "Location access is restricted."
            
        default:
            break
        }
    }
}
