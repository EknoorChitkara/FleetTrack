//
//  Trip.swift
//  FleetTrack
//
//  Professional Fleet Management System
//

import Foundation
import Supabase

// MARK: - Enums

enum TripStatus: String, Codable, CaseIterable, PostgrestFilterValue {
    case scheduled = "Scheduled"
    case ongoing = "In Progress"  // Database uses "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
    
    var postgrestFilterValue: String {
        return self.rawValue
    }
}

// MARK: - Trip Model

struct Trip: Identifiable, Codable, Hashable {
    let id: UUID
    var vehicleId: UUID
    var driverId: UUID
    var status: TripStatus?
    
    // Start location (separate fields per DB schema)
    var startLat: Double?
    var startLong: Double?
    var startAddress: String?
    
    // End location (separate fields per DB schema)
    var endLat: Double?
    var endLong: Double?
    var endAddress: String?
    
    // Trip details
    var startTime: Date?
    var endTime: Date?
    var distance: Double?
    
    // Trip metadata
    var purpose: String?
    var notes: String?
    var createdBy: UUID?
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vehicleId = "vehicle_id"
        case driverId = "driver_id"
        case status
        case startLat = "start_latitude"
        case startLong = "start_longitude"
        case startAddress = "start_address"
        case endLat = "end_latitude"
        case endLong = "end_longitude"
        case endAddress = "end_address"
        case startTime = "start_time"
        case endTime = "end_time"
        case distance
        case purpose
        case notes
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        vehicleId: UUID,
        driverId: UUID,
        status: TripStatus? = .scheduled,
        startLat: Double? = nil,
        startLong: Double? = nil,
        startAddress: String? = nil,
        endLat: Double? = nil,
        endLong: Double? = nil,
        endAddress: String? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        distance: Double? = nil,
        purpose: String? = nil,
        notes: String? = nil,
        createdBy: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vehicleId = vehicleId
        self.driverId = driverId
        self.status = status
        self.startLat = startLat
        self.startLong = startLong
        self.startAddress = startAddress
        self.endLat = endLat
        self.endLong = endLong
        self.endAddress = endAddress
        self.startTime = startTime
        self.endTime = endTime
        self.distance = distance
        self.purpose = purpose
        self.notes = notes
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    /// Convenience computed property to get start location as Location object
    var startLocation: Location? {
        guard let lat = startLat, let long = startLong else { return nil }
        return Location(latitude: lat, longitude: long, address: startAddress ?? "")
    }
    
    /// Convenience computed property to get end location as Location object
    var endLocation: Location? {
        guard let lat = endLat, let long = endLong else { return nil }
        return Location(latitude: lat, longitude: long, address: endAddress ?? "")
    }
    
    var duration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }
    
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        return String(format: "%dh %dm", hours, minutes)
    }
    
    var formattedDistance: String? {
        guard let distance = distance else { return nil }
        return String(format: "%.1f km", distance)
    }
    
    // MARK: - Location Helpers
    
    /// Check if trip has start location coordinates
    var hasStartLocation: Bool {
        startLat != nil && startLong != nil
    }
    
    /// Check if trip has end location coordinates
    var hasEndLocation: Bool {
        endLat != nil && endLong != nil
    }
    
    // MARK: - Validation
    
    /// Validate if trip has minimum required data
    var isValid: Bool {
        // Must have vehicle, driver, and at least addresses
        return startAddress != nil && 
               !startAddress!.isEmpty && 
               endAddress != nil && 
               !endAddress!.isEmpty
    }
    
    /// Check if trip can be started by driver
    var canBeStarted: Bool {
        status == .scheduled && startTime != nil
    }
    
    /// Check if trip can be completed
    var canBeCompleted: Bool {
        status == .ongoing
    }
    
    /// Check if trip is active (scheduled or ongoing)
    var isActive: Bool {
        status == .scheduled || status == .ongoing
    }
}

// MARK: - Mock Data
extension Trip {
    static let mockOngoingTrip = Trip(
        vehicleId: Vehicle.mockVehicle1.id,
        driverId: User.mockDriver.id,
        status: .ongoing,
        startLat: 19.0760,
        startLong: 72.8777,
        startAddress: "Mumbai",
        endLat: 18.5204,
        endLong: 73.8567,
        endAddress: "Pune",
        startTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
        distance: 148.5,
        purpose: "Urgent Delivery",
        createdBy: User.mockFleetManager.id
    )
    
    static let mockCompletedTrip = Trip(
        vehicleId: Vehicle.mockVehicle2.id,
        driverId: User.mockDriver.id,
        status: .completed,
        startLat: 28.6139,
        startLong: 77.2090,
        startAddress: "Delhi",
        endLat: 26.9124,
        endLong: 75.7873,
        endAddress: "Jaipur",
        startTime: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
        endTime: Calendar.current.date(byAdding: .day, value: -1, to: Date())?.addingTimeInterval(3600 * 6),
        distance: 280.0,
        purpose: "Retail Stock",
        createdBy: User.mockFleetManager.id
    )
    
    static let mockTrips: [Trip] = [
        mockOngoingTrip,
        mockCompletedTrip
    ]
}

