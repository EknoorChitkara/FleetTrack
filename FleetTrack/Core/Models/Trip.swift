//
//  Trip.swift
//  FleetTrack
//
//  Professional Fleet Management System
//

import Foundation

// MARK: - Enums

enum TripStatus: String, Codable, CaseIterable {
    case scheduled = "Scheduled"
    case ongoing = "Ongoing"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

// MARK: - Trip Model

struct Trip: Identifiable, Codable, Hashable {
    let id: UUID
    var vehicleId: UUID
    var driverId: UUID
    var status: TripStatus
    
    // Trip details
    var startLocation: Location?
    var endLocation: Location?
    var startTime: Date?
    var endTime: Date?
    var distance: Double? // km
    
    // Trip metadata
    var purpose: String?
    var notes: String?
    var createdBy: UUID // Fleet Manager who created the trip
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        vehicleId: UUID,
        driverId: UUID,
        status: TripStatus = .scheduled,
        startLocation: Location? = nil,
        endLocation: Location? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        distance: Double? = nil,
        purpose: String? = nil,
        notes: String? = nil,
        createdBy: UUID,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vehicleId = vehicleId
        self.driverId = driverId
        self.status = status
        self.startLocation = startLocation
        self.endLocation = endLocation
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
}

// MARK: - Mock Data
extension Trip {
    static let mockOngoingTrip = Trip(
        vehicleId: Vehicle.mockVehicle1.id,
        driverId: User.mockDriver.id,
        status: .ongoing,
        startLocation: Location(latitude: 19.0760, longitude: 72.8777, address: "Mumbai"),
        endLocation: Location(latitude: 18.5204, longitude: 73.8567, address: "Pune"),
        startTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
        distance: 148.5,
        purpose: "Urgent Delivery",
        createdBy: User.mockFleetManager.id
    )
    
    static let mockCompletedTrip = Trip(
        vehicleId: Vehicle.mockVehicle2.id,
        driverId: User.mockDriver.id,
        status: .completed,
        startLocation: Location(latitude: 28.6139, longitude: 77.2090, address: "Delhi"),
        endLocation: Location(latitude: 26.9124, longitude: 75.7873, address: "Jaipur"),
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
