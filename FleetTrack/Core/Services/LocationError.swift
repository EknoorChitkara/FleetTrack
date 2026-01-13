//
//  LocationError.swift
//  FleetTrack
//
//  Location-related error types
//

import Foundation

enum LocationError: LocalizedError {
    case permissionDenied
    case permissionRestricted
    case timeout
    case unavailable
    case geocodingFailed(String)
    case invalidCoordinate
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission was denied"
        case .permissionRestricted:
            return "Location services are restricted on this device"
        case .timeout:
            return "Location request timed out"
        case .unavailable:
            return "Location services are unavailable"
        case .geocodingFailed(let message):
            return "Geocoding failed: \(message)"
        case .invalidCoordinate:
            return "Invalid coordinate provided"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Please enable location access in Settings > FleetTrack > Location"
        case .permissionRestricted:
            return "Location services are disabled by device restrictions"
        case .timeout:
            return "Please try again in an area with better GPS signal"
        case .unavailable:
            return "Please enable Location Services in Settings > Privacy > Location Services"
        case .geocodingFailed:
            return "Please check your internet connection and try again"
        case .invalidCoordinate:
            return "Please select a valid location on the map"
        }
    }
}
