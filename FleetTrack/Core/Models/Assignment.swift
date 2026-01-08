//
//  Assignment.swift
//  FleetTrack
//
//  Created by FleetTrack on 08/01/26.
//

import Foundation

enum AssignmentStatus: String, Codable, CaseIterable {
    case active = "Active"
    case inactive = "Inactive"
    case temporary = "Temporary"
}

struct Assignment: Identifiable, Codable, Hashable {
    let id: UUID
    var vehicleId: UUID
    var driverId: UUID
    var status: AssignmentStatus
    
    // Assignment period
    var assignedDate: Date
    var endDate: Date?
    
    // Assignment details
    var assignedBy: UUID // Fleet Manager ID
    var notes: String?
    var isCurrentAssignment: Bool
    
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        vehicleId: UUID,
        driverId: UUID,
        status: AssignmentStatus = .active,
        assignedDate: Date = Date(),
        endDate: Date? = nil,
        assignedBy: UUID,
        notes: String? = nil,
        isCurrentAssignment: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vehicleId = vehicleId
        self.driverId = driverId
        self.status = status
        self.assignedDate = assignedDate
        self.endDate = endDate
        self.assignedBy = assignedBy
        self.notes = notes
        self.isCurrentAssignment = isCurrentAssignment
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed properties
    var duration: TimeInterval? {
        guard let end = endDate else { return nil }
        return end.timeIntervalSince(assignedDate)
    }
    
    var isTemporary: Bool {
        status == .temporary && endDate != nil
    }
}

// MARK: - Mock Data
extension Assignment {
    static let mockAssignment1 = Assignment(
        vehicleId: Vehicle.mockVehicle1.id,
        driverId: User.mockDriver.id,
        status: .active,
        assignedDate: Calendar.current.date(byAdding: .month, value: -6, to: Date())!,
        assignedBy: User.mockFleetManager.id,
        notes: "Primary vehicle for delivery routes"
    )
    
    static let mockAssignment2 = Assignment(
        vehicleId: Vehicle.mockVehicle3.id,
        driverId: User.mockDriver.id,
        status: .temporary,
        assignedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
        assignedBy: User.mockFleetManager.id,
        notes: "Temporary assignment while primary vehicle is in maintenance",
        isCurrentAssignment: false
    )
    
    static let mockAssignments: [Assignment] = [
        mockAssignment1,
        mockAssignment2
    ]
}
