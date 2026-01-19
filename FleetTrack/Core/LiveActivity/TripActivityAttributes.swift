//
//  TripActivityAttributes.swift
//  FleetTrack
//
//  Live Activities & Dynamic Island - Data Model
//

import ActivityKit
import Foundation

/// Defines the data model for Live Activity on Lock Screen and Dynamic Island
struct TripActivityAttributes: ActivityAttributes {
    
    /// Dynamic content that updates during the trip
    public struct ContentState: Codable, Hashable {
        var destination: String
        var etaMinutes: Int
        var distanceKm: Double
        var status: String // "pickup", "delivering", "completed"
        var driverName: String
    }
    
    /// Static content set when activity starts
    var tripId: String
    var pickupAddress: String
    var vehicleRegistration: String
}
