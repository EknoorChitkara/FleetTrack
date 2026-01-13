//
//  FleetManagerError.swift
//  FleetTrack
//
//  Custom error types for Fleet Manager operations
//

import Foundation

enum FleetManagerError: LocalizedError {
    case missingVehicleId
    case missingDriverId
    case vehicleNotFound(UUID)
    case driverNotFound(UUID)
    case invalidDistance
    case invalidDateTime
    case invalidTripData(String)
    case notAuthenticated
    case databaseError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingVehicleId:
            return "Please select a vehicle for this trip"
        case .missingDriverId:
            return "Please assign a driver to this trip"
        case .vehicleNotFound(let id):
            return "Vehicle with ID \(id.uuidString.prefix(8))... not found"
        case .driverNotFound(let id):
            return "Driver with ID \(id.uuidString.prefix(8))... not found"
        case .invalidDistance:
            return "Please enter a valid distance greater than 0"
        case .invalidDateTime:
            return "Please select a valid date and time for the trip"
        case .invalidTripData(let message):
            return "Invalid trip data: \(message)"
        case .notAuthenticated:
            return "You must be logged in to perform this action"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .missingVehicleId:
            return "Select a vehicle from the dropdown menu"
        case .missingDriverId:
            return "Assign a driver from the available drivers list"
        case .vehicleNotFound, .driverNotFound:
            return "Please refresh the data and try again"
        case .invalidDistance:
            return "Enter the trip distance in kilometers"
        case .invalidDateTime:
            return "Select a future date and time for the trip"
        case .invalidTripData:
            return "Check all required fields and try again"
        case .notAuthenticated:
            return "Please log in and try again"
        case .databaseError, .networkError:
            return "Check your internet connection and try again"
        }
    }
}
