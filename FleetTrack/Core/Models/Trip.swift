//
//  Trip.swift
//  FleetTrack
//
//  Created by FleetTrack on 08/01/26.
//

import Foundation

enum TripStatus: String, Codable, CaseIterable {
    case scheduled = "Scheduled"
    case ongoing = "Ongoing"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

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
    var distance: Double? // in km
    
    // Trip metadata
    var purpose: String?
    var notes: String?
    var createdBy: UUID // Fleet Manager who created the trip
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
    
    // Computed properties
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
        startLocation: Location(
            latitude: 28.7041,
            longitude: 77.1025,
            address: "Delhi Hub"
        ),
        endLocation: Location(
            latitude: 28.5355,
            longitude: 77.3910,
            address: "Noida Sector 62"
        ),
        startTime: Calendar.current.date(byAdding: .hour, value: -1, to: Date()),
        distance: 24.5,
        purpose: "Delivery",
        createdBy: User.mockFleetManager.id
    )
    
    static let mockCompletedTrip = Trip(
        vehicleId: Vehicle.mockVehicle1.id,
        driverId: User.mockDriver.id,
        status: .completed,
        startLocation: Location(
            latitude: 28.7041,
            longitude: 77.1025,
            address: "Delhi Hub"
        ),
        endLocation: Location(
            latitude: 28.4595,
            longitude: 77.0266,
            address: "Ghaziabad"
        ),
        startTime: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
        endTime: Calendar.current.date(byAdding: .hour, value: -22, to: Date()),
        distance: 28.2,
        purpose: "Pickup",
        createdBy: User.mockFleetManager.id
    )
    
    static let mockScheduledTrip = Trip(
        vehicleId: Vehicle.mockVehicle3.id,
        driverId: User.mockDriver.id,
        status: .scheduled,
        startLocation: Location(
            latitude: 28.5355,
            longitude: 77.3910,
            address: "Noida Sector 18"
        ),
        endLocation: Location(
            latitude: 28.4595,
            longitude: 77.0266,
            address: "Gurgaon Sector 29"
        ),
        purpose: "Passenger Transport",
        createdBy: User.mockFleetManager.id
    )
    
    static let mockTrips: [Trip] = [
        mockOngoingTrip,
        mockCompletedTrip,
        mockScheduledTrip
    ]
}
