//
//  AlertModels.swift
//  FleetTrack
//
//  Created for Shared Alert Models
//

import Foundation

struct AlertCreate: Encodable {
    let tripId: UUID?
    let title: String
    let message: String
    let type: String
    let timestamp: String
    let isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case tripId = "trip_id"
        case title
        case message
        case type
        case timestamp
        case isRead = "is_read"
    }
}

struct MaintenanceAlertCreate: Encodable {
    let title: String
    let message: String
    let type: String
    let date: String
    let isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case title
        case message
        case type
        case date
        case isRead = "is_read"
    }
}
