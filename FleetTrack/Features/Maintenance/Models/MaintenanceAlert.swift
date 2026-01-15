//
//  MaintenanceAlert.swift
//  FleetTrack
//

import Foundation

public enum AlertType: String, Codable, CaseIterable {
    case system = "System"
    case emergency = "Emergency"
}

public struct MaintenanceAlert: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var message: String
    public var date: Date
    public var isRead: Bool
    public var type: AlertType

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case message
        case date
        case isRead = "is_read"
        case type
    }

    public init(
        id: UUID = UUID(),
        title: String,
        message: String,
        date: Date = Date(),
        isRead: Bool = false,
        type: AlertType
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.date = date
        self.isRead = isRead
        self.type = type
    }
}
