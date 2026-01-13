//
//  TaskStatus.swift
//  FleetTrack
//
//  Created for Maintenance Module - Task Management
//

import Foundation
import SwiftUI

enum TaskStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case paused = "Paused"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"
    
    var color: Color {
        switch self {
        case .pending:
            return AppTheme.statusWarning
        case .inProgress:
            return AppTheme.accentPrimary
        case .paused:
            return AppTheme.statusIdle
        case .completed:
            return AppTheme.statusActiveText
        case .failed:
            return AppTheme.statusError
        case .cancelled:
            return AppTheme.textTertiary
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "clock.badge.exclamationmark"
        case .inProgress:
            return "gearshape.2.fill"
        case .paused:
            return "pause.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .cancelled:
            return "slash.circle.fill"
        }
    }
}
