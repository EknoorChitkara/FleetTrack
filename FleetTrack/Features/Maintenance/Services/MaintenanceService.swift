//
//  MaintenanceService.swift
//  FleetTrack
//
//  Created for Maintenance Module
//

import Foundation
import Supabase

public class MaintenanceService {
    public static let shared = MaintenanceService()

    // Access the global Supabase client
    private var client: SupabaseClient {
        SupabaseClientManager.shared.client
    }

    private init() {}

    // MARK: - Fetch Operations

    /// Fetch all maintenance tasks from Supabase
    public func fetchMaintenanceTasks() async throws -> [MaintenanceTask] {
        let tasks: [MaintenanceTask] =
            try await client
            .from("maintenance_tasks")
            .select()
            .execute()
            .value

        print("✅ Fetched \(tasks.count) maintenance tasks from Supabase")
        return tasks
    }

    /// Fetch maintenance summary statistics
    public func fetchMaintenanceSummary() async throws -> MaintenanceSummary {
        // Query the maintenance_summary view
        struct SummaryResponse: Codable {
            let completedTasksThisMonth: Int?
            let averageCompletionTimeHours: Double?

            enum CodingKeys: String, CodingKey {
                case completedTasksThisMonth = "completed_tasks_this_month"
                case averageCompletionTimeHours = "average_completion_time_hours"
            }
        }

        let response: [SummaryResponse] =
            try await client
            .from("maintenance_summary")
            .select()
            .execute()
            .value

        // Extract first row (view returns single row)
        let summaryData = response.first

        let summary = MaintenanceSummary(
            completedTasksThisMonth: summaryData?.completedTasksThisMonth ?? 0,
            averageCompletionTimeHours: summaryData?.averageCompletionTimeHours ?? 0.0
        )

        print("✅ Fetched maintenance summary: \(summary.completedTasksThisMonth) completed tasks")
        return summary
    }

    // MARK: - Create Operations

    /// Add a new maintenance task
    public func addMaintenanceTask(_ data: MaintenanceTaskCreationData) async throws {
        let newTask = MaintenanceTask(
            id: UUID(),
            vehicleRegistrationNumber: data.vehicleRegistrationNumber,
            priority: data.priority,
            component: data.component,
            status: data.status,
            dueDate: data.dueDate,
            completedDate: nil,
            partsUsed: data.partsUsed
        )

        try await client
            .from("maintenance_tasks")
            .insert(newTask)
            .execute()

        print(
            "✅ Maintenance task created: \(data.component.rawValue) for \(data.vehicleRegistrationNumber)"
        )
    }

    // MARK: - Update Operations

    /// Update the status of a maintenance task
    public func updateTaskStatus(taskId: UUID, status: String) async throws {
        struct StatusUpdate: Encodable {
            let status: String
            let updatedAt: Date = Date()

            enum CodingKeys: String, CodingKey {
                case status
                case updatedAt = "updated_at"
            }
        }

        let update = StatusUpdate(status: status)

        try await client
            .from("maintenance_tasks")
            .update(update)
            .eq("id", value: taskId)
            .execute()

        print("✅ Task \(taskId) status updated to: \(status)")
    }

    /// Mark a task as completed (Basic status update)
    public func completeTask(taskId: UUID, completedDate: Date = Date()) async throws {
        struct CompletionUpdate: Encodable {
            let status: String = "Completed"
            let completedDate: Date
            let isLocked: Bool = true
            let updatedAt: Date = Date()

            enum CodingKeys: String, CodingKey {
                case status
                case completedDate = "completed_date"
                case isLocked = "is_locked"
                case updatedAt = "updated_at"
            }
        }

        let update = CompletionUpdate(completedDate: completedDate)

        try await client
            .from("maintenance_tasks")
            .update(update)
            .eq("id", value: taskId)
            .execute()

        print("✅ Task \(taskId) marked as completed")
    }

    // MARK: - Delete Operations

    /// Delete a maintenance task
    public func deleteTask(taskId: UUID) async throws {
        try await client
            .from("maintenance_tasks")
            .delete()
            .eq("id", value: taskId)
            .execute()

        print("✅ Task \(taskId) deleted")
    }

    // MARK: - Enhanced Task Management Operations

    /// Start a task
    public func startTask(taskId: UUID) async throws {
        struct TaskUpdate: Encodable {
            let status: String = "In Progress"
            let startedAt: Date = Date()
            let updatedAt: Date = Date()

            enum CodingKeys: String, CodingKey {
                case status
                case startedAt = "started_at"
                case updatedAt = "updated_at"
            }
        }

        let update = TaskUpdate()

        try await client
            .from("maintenance_tasks")
            .update(update)
            .eq("id", value: taskId)
            .execute()

        print("✅ Task \(taskId) started")
    }

    /// Pause a task
    public func pauseTask(taskId: UUID) async throws {
        struct TaskUpdate: Encodable {
            let status: String = "Paused"
            let pausedAt: Date = Date()
            let updatedAt: Date = Date()

            enum CodingKeys: String, CodingKey {
                case status
                case pausedAt = "paused_at"
                case updatedAt = "updated_at"
            }
        }

        let update = TaskUpdate()

        try await client
            .from("maintenance_tasks")
            .update(update)
            .eq("id", value: taskId)
            .execute()

        print("✅ Task \(taskId) paused")
    }

    /// Resume a task
    public func resumeTask(taskId: UUID) async throws {
        struct TaskUpdate: Encodable {
            let status: String = "In Progress"
            let updatedAt: Date = Date()

            enum CodingKeys: String, CodingKey {
                case status
                case updatedAt = "updated_at"
            }
        }

        let update = TaskUpdate()

        try await client
            .from("maintenance_tasks")
            .update(update)
            .eq("id", value: taskId)
            .execute()

        print("✅ Task \(taskId) resumed")
    }

    /// Mark task as failed
    public func failTask(taskId: UUID, reason: String) async throws {
        struct TaskUpdate: Encodable {
            let status: String = "Failed"
            let failedReason: String
            let completedDate: Date = Date()
            let isLocked: Bool = true
            let updatedAt: Date = Date()

            enum CodingKeys: String, CodingKey {
                case status
                case failedReason = "failed_reason"
                case completedDate = "completed_date"
                case isLocked = "is_locked"
                case updatedAt = "updated_at"
            }
        }

        let update = TaskUpdate(failedReason: reason)

        try await client
            .from("maintenance_tasks")
            .update(update)
            .eq("id", value: taskId)
            .execute()

        print("✅ Task \(taskId) marked as failed")
    }

    /// Add a part usage to a task
    public func addPart(taskId: UUID, part: PartUsage) async throws {
        // Fetch current parts
        let tasks: [MaintenanceTask] =
            try await client
            .from("maintenance_tasks")
            .select("parts_used")
            .eq("id", value: taskId)
            .execute()
            .value

        var parts = tasks.first?.partsUsed ?? []
        parts.append(part)

        try await client
            .from("maintenance_tasks")
            .update(["parts_used": parts])
            .eq("id", value: taskId)
            .execute()

        print("✅ Part added to task \(taskId)")
    }

    /// Remove a part usage from a task
    public func removePart(taskId: UUID, part: PartUsage) async throws {
        // Fetch current parts
        let tasks: [MaintenanceTask] =
            try await client
            .from("maintenance_tasks")
            .select("parts_used")
            .eq("id", value: taskId)
            .execute()
            .value

        var parts = tasks.first?.partsUsed ?? []
        parts.removeAll { $0 == part }

        try await client
            .from("maintenance_tasks")
            .update(["parts_used": parts])
            .eq("id", value: taskId)
            .execute()

        print("✅ Part removed from task \(taskId)")
    }

    /// Update repair log
    public func updateRepairLog(
        taskId: UUID, repairDescription: String?, laborHours: Double?, partsUsed: [PartUsage]?
    ) async throws {
        struct RepairLogUpdate: Encodable {
            let repairDescription: String?
            let laborHours: Double?
            let partsUsed: [PartUsage]?
            let updatedAt: Date = Date()

            enum CodingKeys: String, CodingKey {
                case repairDescription = "repair_description"
                case laborHours = "labor_hours"
                case partsUsed = "parts_used"
                case updatedAt = "updated_at"
            }
        }

        let update = RepairLogUpdate(
            repairDescription: repairDescription,
            laborHours: laborHours,
            partsUsed: partsUsed
        )

        try await client
            .from("maintenance_tasks")
            .update(update)
            .eq("id", value: taskId)
            .execute()

        print("✅ Repair log updated for task \(taskId)")
    }

    /// Complete task with repair log
    public func completeTaskWithRepairLog(
        taskId: UUID, repairDescription: String, laborHours: Double, partsUsed: [PartUsage]
    ) async throws {
        struct CompletionUpdate: Encodable {
            let status: String = "Completed"
            let completedDate: Date = Date()
            let isLocked: Bool = true
            let repairDescription: String
            let laborHours: Double
            let partsUsed: [PartUsage]
            let updatedAt: Date = Date()

            enum CodingKeys: String, CodingKey {
                case status
                case completedDate = "completed_date"
                case isLocked = "is_locked"
                case repairDescription = "repair_description"
                case laborHours = "labor_hours"
                case partsUsed = "parts_used"
                case updatedAt = "updated_at"
            }
        }

        let update = CompletionUpdate(
            repairDescription: repairDescription,
            laborHours: laborHours,
            partsUsed: partsUsed
        )

        try await client
            .from("maintenance_tasks")
            .update(update)
            .eq("id", value: taskId)
            .execute()

        print("✅ Task \(taskId) marked as completed and locked")
    }

    /// Request reschedule
    func requestReschedule(
        taskId: UUID, newDueDate: Date, reason: String, requestedBy: UUID, requestedByName: String
    ) async throws {
        let request = RescheduleRequest(
            taskId: taskId,
            requestedBy: requestedBy,
            requestedByName: requestedByName,
            newDueDate: newDueDate,
            reason: reason
        )

        try await client
            .from("reschedule_requests")
            .insert(request)
            .execute()

        print("✅ Reschedule request created for task \(taskId)")
    }

    /// Request cancellation
    func requestCancellation(
        taskId: UUID, reason: String, requestedBy: UUID, requestedByName: String
    ) async throws {
        let request = CancelRequest(
            taskId: taskId,
            requestedBy: requestedBy,
            requestedByName: requestedByName,
            reason: reason
        )

        try await client
            .from("cancel_requests")
            .insert(request)
            .execute()

        print("✅ Cancel request created for task \(taskId)")
    }

    /// Fetch vehicle details
    func fetchVehicle(byId vehicleId: UUID) async throws -> Vehicle? {
        let vehicles: [Vehicle] =
            try await client
            .from("vehicles")
            .select()
            .eq("id", value: vehicleId)
            .execute()
            .value

        return vehicles.first
    }

    /// Fetch vehicle by registration number
    func fetchVehicle(byRegistration registration: String) async throws -> Vehicle? {
        let vehicles: [Vehicle] =
            try await client
            .from("vehicles")
            .select()
            .eq("registration_number", value: registration)
            .execute()
            .value

        return vehicles.first
    }

    /// Fetch driver details
    func fetchDriver(byId driverId: UUID) async throws -> Driver? {
        let drivers: [Driver] =
            try await client
            .from("drivers")
            .select()
            .eq("id", value: driverId)
            .execute()
            .value

        return drivers.first
    }

    /// Add change history entry
    func addChangeHistory(entry: ChangeHistoryEntry) async throws {
        try await client
            .from("change_history")
            .insert(entry)
            .execute()

        print("✅ Change history recorded for task \(entry.taskId)")
    }

    /// Fetch change history for a task
    func fetchChangeHistory(taskId: UUID) async throws -> [ChangeHistoryEntry] {
        let history: [ChangeHistoryEntry] =
            try await client
            .from("change_history")
            .select()
            .eq("task_id", value: taskId)
            .order("edited_at", ascending: false)
            .execute()
            .value

        return history
    }

    // MARK: - Alerts Operations

    /// Fetch all maintenance alerts
    func fetchAlerts() async throws -> [MaintenanceAlert] {
        let alerts: [MaintenanceAlert] =
            try await client
            .from("maintenance_alerts")
            .select()
            .order("date", ascending: false)
            .execute()
            .value

        return alerts
    }

    /// Mark an alert as read
    func markAlertAsRead(alertId: UUID) async throws {
        try await client
            .from("maintenance_alerts")
            .update(["is_read": true])
            .eq("id", value: alertId)
            .execute()

        print("✅ Alert \(alertId) marked as read")
    }

    /// Delete an alert
    func deleteAlert(alertId: UUID) async throws {
        try await client
            .from("maintenance_alerts")
            .delete()
            .eq("id", value: alertId)
            .execute()

        print("✅ Alert \(alertId) deleted")
    }
}
