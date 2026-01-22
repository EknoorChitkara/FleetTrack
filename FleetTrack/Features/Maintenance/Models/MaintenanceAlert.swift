//
//  MaintenanceAlert.swift
//  FleetTrack
//

import Foundation

public enum AlertType: String, Codable, CaseIterable {
    case system = "System"
    case emergency = "Emergency"
    case inventory = "Inventory"
    case maintenance = "Maintenance"
}

public struct MaintenanceAlert: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var message: String
    public var date: Date
    public var isRead: Bool
    public var type: AlertType
    
    // Emergency alert fields (optional)
    public var vehicleId: UUID?
    public var vehicleRegistration: String?
    public var driverId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case message
        case date
        case isRead = "is_read"
        case type
        case vehicleId = "vehicle_id"
        case vehicleRegistration = "vehicle_registration"
        case driverId = "driver_id"
    }

    public init(
        id: UUID = UUID(),
        title: String,
        message: String,
        date: Date = Date(),
        isRead: Bool = false,
        type: AlertType,
        vehicleId: UUID? = nil,
        vehicleRegistration: String? = nil,
        driverId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.date = date
        self.isRead = isRead
        self.type = type
        self.vehicleId = vehicleId
        self.vehicleRegistration = vehicleRegistration
        self.driverId = driverId
    }
}
