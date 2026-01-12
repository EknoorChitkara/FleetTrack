//
//  MaintenanceAlert.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//


import Foundation

enum AlertType: String, Codable, CaseIterable {
    case system = "System"
    case emergency = "Emergency"
}

struct MaintenanceAlert: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var message: String
    var date: Date
    var isRead: Bool
    var type: AlertType
    
    init(
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
