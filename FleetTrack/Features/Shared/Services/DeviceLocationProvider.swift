//
//  DeviceLocationProvider.swift
//  FleetTrack
//
//  Created for Fleet Manager Trip Map Integration
//

import Foundation
import CoreLocation
import Combine

/// Location provider that uses the device's local GPS
/// Used by Drivers for navigation
class DeviceLocationProvider: TripLocationProvider {
    @Published var currentLocation: Location?
    @Published var heading: Double? = 0.0 // CoreLocation doesn't always provide heading immediately
    @Published var status: LocationProviderStatus = .offline
    @Published var isUpdating: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let locationService = LocationService.shared
    
    init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        locationService.$currentLocation
            .sink { [weak self] clLocation in
                guard let self = self, let clLocation = clLocation else { return }
                
                self.currentLocation = Location(
                    latitude: clLocation.coordinate.latitude,
                    longitude: clLocation.coordinate.longitude,
                    address: "Current Location", // Address reverse geocoding is separate
                    timestamp: clLocation.timestamp
                )
                
                // Assuming active if we get updates
                self.status = .active
                
                // Extract heading if available (course)
                if clLocation.course >= 0 {
                    self.heading = clLocation.course
                }
            }
            .store(in: &cancellables)
            
        locationService.$isUpdatingLocation
            .assign(to: \.isUpdating, on: self)
            .store(in: &cancellables)
    }
    
    func startTracking() {
        locationService.requestWhenInUseAuthorization()
        locationService.configureForMode(.tracking)
        locationService.startUpdatingLocation()
        status = .connecting
    }
    
    func stopTracking() {
        locationService.stopLocationUpdates()
        status = .offline
    }
}
