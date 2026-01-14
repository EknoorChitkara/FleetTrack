//
//  VehicleInspection.swift
//  FleetTrack
//
//  Created by FleetTrack
//

import Foundation

enum InspectionStatus: String, Codable, CaseIterable {
    case passed = "Passed"
    case failed = "Failed"
    case pending = "Pending"
}

enum InspectionItemStatus: String, Codable {
    case pass = "Pass"
    case fail = "Fail"
    case notApplicable = "N/A"
}

struct InspectionItem: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var status: InspectionItemStatus
    var comment: String?
    
    init(id: UUID = UUID(), name: String, status: InspectionItemStatus = .pass, comment: String? = nil) {
        self.id = id
        self.name = name
        self.status = status
        self.comment = comment
    }
}

struct VehicleInspection: Identifiable, Codable, Hashable {
    let id: UUID
    var vehicleId: UUID
    var driverId: UUID
    var date: Date
    var items: [InspectionItem]
    var photoURLs: [String]
    var status: InspectionStatus
    var notes: String?
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vehicleId = "vehicle_id"
        case driverId = "driver_id"
        case date
        case items
        case photoURLs = "photo_urls"
        case status
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        vehicleId: UUID,
        driverId: UUID,
        date: Date = Date(),
        items: [InspectionItem] = [],
        photoURLs: [String] = [],
        status: InspectionStatus = .pending,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vehicleId = vehicleId
        self.driverId = driverId
        self.date = date
        self.items = items
        self.photoURLs = photoURLs
        self.status = status
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Default Checklist Items
extension VehicleInspection {
    static var defaultChecklistItems: [InspectionItem] {
        [
            InspectionItem(name: "Tires"),
            InspectionItem(name: "Brakes"),
            InspectionItem(name: "Lights"),
            InspectionItem(name: "Oil"),
            InspectionItem(name: "Fuel"),
            InspectionItem(name: "Mirrors"),
            InspectionItem(name: "Wipers"),
            InspectionItem(name: "Horn")
        ]
    }
}

// MARK: - Mock Data
extension VehicleInspection {
    static let mockInspection = VehicleInspection(
        vehicleId: Vehicle.mockVehicle1.id,
        driverId: User.mockDriver.id,
        items: defaultChecklistItems,
        status: .passed,
        notes: "All checks passed. Ready for trip."
    )
}
