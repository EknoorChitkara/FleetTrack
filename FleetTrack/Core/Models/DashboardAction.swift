//
//  DashboardAction.swift
//  FleetTrack
//
//  Created by FleetTrack on 16/01/26.
//

import Foundation
import SwiftUI

enum DashboardActionType: String, Codable, CaseIterable {
    case vehicleInspection = "Vehicle Inspection"
    case reportIssue = "Report Issue"
}

struct DashboardAction: Identifiable, Hashable {
    let id: UUID
    let type: DashboardActionType
    let title: String
    let subtitle: String
    let iconName: String
    let iconColor: Color? // Optional override, otherwise derived from type/UI
    
    init(
        id: UUID = UUID(),
        type: DashboardActionType,
        title: String,
        subtitle: String,
        iconName: String,
        iconColor: Color? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.iconColor = iconColor
    }
}

// MARK: - Mock Data
extension DashboardAction {
    static let inspection = DashboardAction(
        type: .vehicleInspection,
        title: "Vehicle Inspection",
        subtitle: "Daily checklist & maintenance",
        iconName: "car.circle" // Or "car.fill" inside a custom frame
    )
    
    static let reportIssue = DashboardAction(
        type: .reportIssue,
        title: "Report Issue",
        subtitle: "Emergency or maintenance alert",
        iconName: "exclamationmark.triangle"
    )
    
    static let allActions: [DashboardAction] = [inspection, reportIssue]
}
