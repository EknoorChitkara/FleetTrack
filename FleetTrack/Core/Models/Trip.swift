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
