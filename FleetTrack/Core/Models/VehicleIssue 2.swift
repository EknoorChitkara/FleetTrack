//
//  VehicleIssue.swift
//  FleetTrack
//
//  Created for Driver
//

import Foundation

enum IssueType: String, Codable, CaseIterable {
    case tirePuncture = "Tire Puncture"
    case engineIssue = "Engine Issue"
    case brakeProblem = "Brake Problem"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .tirePuncture: return "circle.dashed" // refined in view
        case .engineIssue: return "engine.combustion"
        case .brakeProblem: return "exclamationmark.octagon"
        case .other: return "ellipsis"
        }
    }
}

enum IssueSeverity: String, Codable, CaseIterable {
    case normal = "Normal"
    case warning = "Warning"
    case critical = "Critical"
    
    var colorName: String {
        switch self {
        case .normal: return "gray"
        case .warning: return "orange"
        case .critical: return "red"
        }
    }
}

struct VehicleIssue: Identifiable, Codable {
    let id: UUID
    var vehicleId: UUID
    var driverId: UUID
    var type: IssueType
    var severity: IssueSeverity
    var description: String
    var photoURLs: [String]
    var reportedAt: Date
    var status: String // "Reported", "Investigating", "Resolved"
    
    init(
        id: UUID = UUID(),
        vehicleId: UUID,
        driverId: UUID,
        type: IssueType,
        severity: IssueSeverity = .normal,
        description: String = "",
        photoURLs: [String] = [],
        reportedAt: Date = Date(),
        status: String = "Reported"
    ) {
        self.id = id
        self.vehicleId = vehicleId
        self.driverId = driverId
        self.type = type
        self.severity = severity
        self.description = description
        self.photoURLs = photoURLs
        self.reportedAt = reportedAt
        self.status = status
    }
}
