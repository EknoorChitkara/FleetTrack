//
//  MaintenanceModels.swift
//  FleetTrack
//
//

import Foundation
import SwiftUI

// MARK: - Enums

public enum MaintenancePriority: String, Codable, CaseIterable, Hashable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    public var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

public enum MaintenanceComponent: String, Codable, CaseIterable, Identifiable, Hashable {
    case engine = "Engine"
    case oil = "Oil"
    case oilChange = "Oil Change"
    case tires = "Tires"
    case tireReplacement = "Tire Replacement"
    case brakes = "Brakes"
    case brakeInspection = "Brake Inspection"
    case battery = "Battery"
    case transmission = "Transmission"
    case suspension = "Suspension"
    case electrical = "Electrical"
    case coolingSystem = "Cooling System"
    case other = "Other"

    public var id: String { rawValue }
}

public enum TaskType: String, Codable, CaseIterable, Hashable {
    case scheduled = "Scheduled"
    case emergency = "Emergency"

    public var icon: String {
        switch self {
        case .scheduled:
            return "calendar.badge.clock"
        case .emergency:
            return "exclamationmark.triangle.fill"
        }
    }
}

public enum TaskStatus: String, Codable, CaseIterable, Hashable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case paused = "Paused"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"

    public var color: Color {
        switch self {
        case .pending:
            return .orange
        case .inProgress:
            return .blue
        case .paused:
            return .gray
        case .completed:
            return Color(hexCode: "2D7D46")
        case .failed:
            return .red
        case .cancelled:
            return .secondary
        }
    }

    public var icon: String {
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

// MARK: - Models

public struct PartUsage: Codable, Hashable, Equatable {
    public var partId: UUID?
    public var partName: String
    public var quantity: Int
    public var unitPrice: Double

    public var totalCost: Double {
        Double(quantity) * unitPrice
    }

    enum CodingKeys: String, CodingKey {
        case partId = "part_id"
        case partName = "part_name"
        case quantity
        case unitPrice = "unit_price"
    }

    public init(
        partId: UUID? = nil,
        partName: String,
        quantity: Int,
        unitPrice: Double
    ) {
        self.partId = partId
        self.partName = partName
        self.quantity = quantity
        self.unitPrice = unitPrice
    }
}

public struct MaintenanceTask: Identifiable, Codable, Hashable, Equatable {
    public let id: UUID
    public var vehicleRegistrationNumber: String
    public var priority: MaintenancePriority
    public var component: MaintenanceComponent
    public var status: String  // Keep as String for backward compatibility
    public var dueDate: Date
    public var completedDate: Date?
    public var partsUsed: [PartUsage]
    public var createdAt: Date
    public var updatedAt: Date

    // NEW FIELDS for enhanced task management
    public var taskType: TaskType
    public var description: String?
    public var estimatedServiceHours: Double?
    public var assignedDriverId: UUID?
    public var assignedVehicleId: UUID?
    public var isLocked: Bool
    public var laborHours: Double?
    public var repairDescription: String?
    public var startedAt: Date?
    public var pausedAt: Date?
    public var failedReason: String?

    enum CodingKeys: String, CodingKey {
        case id
        case vehicleRegistrationNumber = "vehicle_registration_number"
        case priority
        case component
        case status
        case dueDate = "due_date"
        case completedDate = "completed_date"
        case partsUsed = "parts_used"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case taskType = "task_type"
        case description
        case estimatedServiceHours = "estimated_service_hours"
        case assignedDriverId = "assigned_driver_id"
        case assignedVehicleId = "assigned_vehicle_id"
        case isLocked = "is_locked"
        case laborHours = "labor_hours"
        case repairDescription = "repair_description"
        case startedAt = "started_at"
        case pausedAt = "paused_at"
        case failedReason = "failed_reason"
    }

    public init(
        id: UUID = UUID(),
        vehicleRegistrationNumber: String,
        priority: MaintenancePriority,
        component: MaintenanceComponent,
        status: String = "Pending",
        dueDate: Date,
        completedDate: Date? = nil,
        partsUsed: [PartUsage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        taskType: TaskType = .scheduled,
        description: String? = nil,
        estimatedServiceHours: Double? = nil,
        assignedDriverId: UUID? = nil,
        assignedVehicleId: UUID? = nil,
        isLocked: Bool = false,
        laborHours: Double? = nil,
        repairDescription: String? = nil,
        startedAt: Date? = nil,
        pausedAt: Date? = nil,
        failedReason: String? = nil
    ) {
        self.id = id
        self.vehicleRegistrationNumber = vehicleRegistrationNumber
        self.priority = priority
        self.component = component
        self.status = status
        self.dueDate = dueDate
        self.completedDate = completedDate
        self.partsUsed = partsUsed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.taskType = taskType
        self.description = description
        self.estimatedServiceHours = estimatedServiceHours
        self.assignedDriverId = assignedDriverId
        self.assignedVehicleId = assignedVehicleId
        self.isLocked = isLocked
        self.laborHours = laborHours
        self.repairDescription = repairDescription
        self.startedAt = startedAt
        self.pausedAt = pausedAt
        self.failedReason = failedReason
    }

    // MARK: - Computed Properties

    public var totalPartsCost: Double {
        partsUsed.reduce(0.0) { $0 + $1.totalCost }
    }

    public var isPending: Bool {
        status == "Pending"
    }

    public var isCompleted: Bool {
        status == "Completed"
    }

    public var isOverdue: Bool {
        !isCompleted && dueDate < Date()
    }

    public var taskStatusEnum: TaskStatus {
        TaskStatus(rawValue: status) ?? .pending
    }

    public var canBeEdited: Bool {
        !isLocked && !isCompleted
    }
    
    // Check if task is paused based on pausedAt field
    public var isPaused: Bool {
        status == "In Progress" && pausedAt != nil
    }
    
    // Check if task is failed based on Cancelled status with failedReason
    public var isFailed: Bool {
        status == "Cancelled" && failedReason != nil
    }

    public var canBeStarted: Bool {
        status == "Pending"
    }

    public var canBePaused: Bool {
        status == "In Progress" && pausedAt == nil
    }

    public var canBeResumed: Bool {
        isPaused
    }

    public var canBeCompleted: Bool {
        status == "In Progress"
    }

    public var totalCost: Double {
        totalPartsCost + (laborHours ?? 0) * 250.0  // ₹250/hour labor rate
    }
}

// MARK: - Task Creation Data

public struct MaintenanceTaskCreationData {
    public var vehicleRegistrationNumber: String = ""
    public var priority: MaintenancePriority = .medium
    public var component: MaintenanceComponent = .engine
    public var status: String = "Pending"
    public var dueDate: Date = Date()
    public var partsUsed: [PartUsage] = []

    public init(
        vehicleRegistrationNumber: String = "",
        priority: MaintenancePriority = .medium,
        component: MaintenanceComponent = .engine,
        status: String = "Pending",
        dueDate: Date = Date(),
        partsUsed: [PartUsage] = []
    ) {
        self.vehicleRegistrationNumber = vehicleRegistrationNumber
        self.priority = priority
        self.component = component
        self.status = status
        self.dueDate = dueDate
        self.partsUsed = partsUsed
    }

    /// Convert to MaintenanceTask for database insertion
    public func toMaintenanceTask() -> MaintenanceTask {
        MaintenanceTask(
            id: UUID(),
            vehicleRegistrationNumber: vehicleRegistrationNumber,
            priority: priority,
            component: component,
            status: status,
            dueDate: dueDate,
            completedDate: nil,
            partsUsed: partsUsed,
            createdAt: Date(),
            updatedAt: Date(),
            taskType: .scheduled
        )
    }
}
