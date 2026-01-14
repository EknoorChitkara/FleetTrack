//
//  RescheduleRequest.swift
//  FleetTrack
//
//  Created for Maintenance Module - Task Management
//

import Foundation
import SwiftUI

// MARK: - Approval Status

enum ApprovalStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"
    
    var color: Color {
        switch self {
        case .pending:
            return AppTheme.statusWarning
        case .approved:
            return AppTheme.statusActiveText
        case .rejected:
            return AppTheme.statusError
        }
    }
}

// MARK: - Reschedule Request

struct RescheduleRequest: Codable, Identifiable, Hashable {
    let id: UUID
    var taskId: UUID
    var requestedBy: UUID // Maintenance staff user ID
    var requestedByName: String? // For display
    var newDueDate: Date
    var reason: String
    var approvalStatus: ApprovalStatus
    var approvedBy: UUID?
    var approvedByName: String? // For display
    var approvedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case requestedBy = "requested_by"
        case requestedByName = "requested_by_name"
        case newDueDate = "new_due_date"
        case reason
        case approvalStatus = "approval_status"
        case approvedBy = "approved_by"
        case approvedByName = "approved_by_name"
        case approvedAt = "approved_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        taskId: UUID,
        requestedBy: UUID,
        requestedByName: String? = nil,
        newDueDate: Date,
        reason: String,
        approvalStatus: ApprovalStatus = .pending,
        approvedBy: UUID? = nil,
        approvedByName: String? = nil,
        approvedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.taskId = taskId
        self.requestedBy = requestedBy
        self.requestedByName = requestedByName
        self.newDueDate = newDueDate
        self.reason = reason
        self.approvalStatus = approvalStatus
        self.approvedBy = approvedBy
        self.approvedByName = approvedByName
        self.approvedAt = approvedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Cancel Request

struct CancelRequest: Codable, Identifiable, Hashable {
    let id: UUID
    var taskId: UUID
    var requestedBy: UUID
    var requestedByName: String?
    var reason: String
    var approvalStatus: ApprovalStatus
    var approvedBy: UUID?
    var approvedByName: String?
    var approvedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case requestedBy = "requested_by"
        case requestedByName = "requested_by_name"
        case reason
        case approvalStatus = "approval_status"
        case approvedBy = "approved_by"
        case approvedByName = "approved_by_name"
        case approvedAt = "approved_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        taskId: UUID,
        requestedBy: UUID,
        requestedByName: String? = nil,
        reason: String,
        approvalStatus: ApprovalStatus = .pending,
        approvedBy: UUID? = nil,
        approvedByName: String? = nil,
        approvedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.taskId = taskId
        self.requestedBy = requestedBy
        self.requestedByName = requestedByName
        self.reason = reason
        self.approvalStatus = approvalStatus
        self.approvedBy = approvedBy
        self.approvedByName = approvedByName
        self.approvedAt = approvedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
