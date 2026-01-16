//
//  TripLocationProvider.swift
//  FleetTrack
//
//  Created for Fleet Manager Trip Map Integration
//

import Foundation
import CoreLocation
import Combine

/// Status of the location provider
enum LocationProviderStatus {
    case active
    case stale(since: Date)
    case offline
    case connecting
}

/// Protocol to abstract valid location sources for the trip map
protocol TripLocationProvider: ObservableObject {
    /// The current location of the tracked entity (vehicle or device)
    var currentLocation: Location? { get }
    
    /// The current heading/bearing (0-360)
    var heading: Double? { get }
    
    /// Status of the connection/data freshness
    var status: LocationProviderStatus { get }
    
    /// Whether location updates are actively being received
    var isUpdating: Bool { get }
    
    /// Start receiving updates
    func startTracking()
    
    /// Stop receiving updates
    func stopTracking()
}

// Default implementation for optional requirements
extension TripLocationProvider {
    var isStale: Bool {
        if case .stale = status { return true }
        return false
    }
}
