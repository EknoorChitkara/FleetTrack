//
//  TaskType.swift
//  FleetTrack
//
//  Created for Maintenance Module - Task Management
//

import Foundation

enum TaskType: String, Codable, CaseIterable {
    case scheduled = "Scheduled"
    case emergency = "Emergency"
    
    var icon: String {
        switch self {
        case .scheduled:
            return "calendar.badge.clock"
        case .emergency:
            return "exclamationmark.triangle.fill"
        }
    }
}
