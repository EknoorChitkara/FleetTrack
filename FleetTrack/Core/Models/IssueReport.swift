//
//  IssueReport.swift
//  FleetTrack
//
//  Created by FleetTrack on 08/01/26.
//

import Foundation

enum IssuePriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

enum IssueStatus: String, Codable, CaseIterable {
    case reported = "Reported"
    case acknowledged = "Acknowledged"
    case inProgress = "In Progress"
    case resolved = "Resolved"
    case closed = "Closed"
}

enum IssueCategory: String, Codable, CaseIterable {
    case mechanical = "Mechanical"
    case electrical = "Electrical"
    case bodyDamage = "Body Damage"
    case safety = "Safety"
    case performance = "Performance"
    case other = "Other"
}

struct IssueReport: Identifiable, Codable, Hashable {
    let id: UUID
    var vehicleId: UUID
    var reportedBy: UUID // Driver ID
    var assignedTo: UUID? // Maintenance Personnel ID
    
    // Issue details
    var title: String
    var description: String
    var category: IssueCategory
    var priority: IssuePriority
    var status: IssueStatus
    
    // Tracking
    var reportedAt: Date
    var acknowledgedAt: Date?
    var resolvedAt: Date?
    var closedAt: Date?
    
    // Location and context
    var vehicleMileageAtReport: Double?
    var locationWhenReported: Location?
    
    // Resolution
    var resolutionNotes: String?
    var relatedMaintenanceRecordId: UUID?
    
    // Photos (URLs or identifiers)
    var photoURLs: [String]
    
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        vehicleId: UUID,
        reportedBy: UUID,
        assignedTo: UUID? = nil,
        title: String,
        description: String,
        category: IssueCategory,
        priority: IssuePriority,
        status: IssueStatus = .reported,
        reportedAt: Date = Date(),
        acknowledgedAt: Date? = nil,
        resolvedAt: Date? = nil,
        closedAt: Date? = nil,
        vehicleMileageAtReport: Double? = nil,
        locationWhenReported: Location? = nil,
        resolutionNotes: String? = nil,
        relatedMaintenanceRecordId: UUID? = nil,
        photoURLs: [String] = [],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vehicleId = vehicleId
        self.reportedBy = reportedBy
        self.assignedTo = assignedTo
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.status = status
        self.reportedAt = reportedAt
        self.acknowledgedAt = acknowledgedAt
        self.resolvedAt = resolvedAt
        self.closedAt = closedAt
        self.vehicleMileageAtReport = vehicleMileageAtReport
        self.locationWhenReported = locationWhenReported
        self.resolutionNotes = resolutionNotes
        self.relatedMaintenanceRecordId = relatedMaintenanceRecordId
        self.photoURLs = photoURLs
        self.updatedAt = updatedAt
    }
    
    // Computed properties
    var isOpen: Bool {
        status != .resolved && status != .closed
    }
    
    var timeToResolve: TimeInterval? {
        guard let resolved = resolvedAt else { return nil }
        return resolved.timeIntervalSince(reportedAt)
    }
}

// MARK: - Mock Data
extension IssueReport {
    static let mockIssue1 = IssueReport(
        vehicleId: Vehicle.mockVehicle1.id,
        reportedBy: User.mockDriver.id,
        assignedTo: User.mockMaintenancePersonnel.id,
        title: "Engine Warning Light",
        description: "Check engine light came on during trip. Engine seems to be running normally but light is persistent.",
        category: .mechanical,
        priority: .medium,
        status: .inProgress,
        reportedAt: Calendar.current.date(byAdding: .hour, value: -5, to: Date())!,
        acknowledgedAt: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!,
        vehicleMileageAtReport: 45180,
        locationWhenReported: Location(
            latitude: 28.5355,
            longitude: 77.3910,
            address: "Sector 18, Noida"
        )
    )
    
    static let mockIssue2 = IssueReport(
        vehicleId: Vehicle.mockVehicle1.id,
        reportedBy: User.mockDriver.id,
        title: "Unusual Brake Noise",
        description: "Hearing squeaking noise when applying brakes",
        category: .safety,
        priority: .high,
        status: .reported,
        reportedAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!,
        vehicleMileageAtReport: 45225
    )
    
    static let mockIssue3 = IssueReport(
        vehicleId: Vehicle.mockVehicle3.id,
        reportedBy: User.mockDriver.id,
        assignedTo: User.mockMaintenancePersonnel.id,
        title: "Air Conditioning Not Working",
        description: "AC stopped blowing cold air. Only warm air coming out.",
        category: .mechanical,
        priority: .low,
        status: .resolved,
        reportedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
        acknowledgedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
        resolvedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        vehicleMileageAtReport: 67450,
        resolutionNotes: "Recharged AC refrigerant. System tested and working properly."
    )
    
    static let mockIssues: [IssueReport] = [
        mockIssue1,
        mockIssue2,
        mockIssue3
    ]
}
