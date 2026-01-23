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
        print("📊 Fetching maintenance summary...")
        
        // Fetch all completed tasks
        let tasks: [MaintenanceTask] = try await client
            .from("maintenance_tasks")
            .select()
            .eq("status", value: "Completed")
            .execute()
            .value
        
        // Get current month's date range
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        // Filter tasks completed this month
        let completedThisMonth = tasks.filter { task in
            guard let completedDate = task.completedDate else { return false }
            return completedDate >= startOfMonth
        }
        
        // Calculate average completion time from labor hours
        let tasksWithLaborHours = completedThisMonth.filter { $0.laborHours != nil && $0.laborHours! > 0 }
        let averageCompletionTime: Double
        
        if !tasksWithLaborHours.isEmpty {
            let totalLaborHours = tasksWithLaborHours.reduce(0.0) { $0 + ($1.laborHours ?? 0.0) }
            averageCompletionTime = totalLaborHours / Double(tasksWithLaborHours.count)
        } else {
            averageCompletionTime = 0.0
        }
        
        let summary = MaintenanceSummary(
            completedTasksThisMonth: completedThisMonth.count,
            averageCompletionTimeHours: averageCompletionTime
        )
        
        print("✅ Summary: \(summary.completedTasksThisMonth) completed this month, \(String(format: "%.1f", summary.averageCompletionTimeHours))h avg labor time")
        
        return summary
    }

    // MARK: - Create Operations

    /// Add a new maintenance task
    public func addMaintenanceTask(_ data: MaintenanceTaskCreationData) async throws {
        print("🔧 ========== ADDING MAINTENANCE TASK ==========")
        print("📋 Table: maintenance_tasks")
        print("🚗 Vehicle Registration: \(data.vehicleRegistrationNumber)")
        print("⚡ Priority: \(data.priority)")
        print("🔩 Component: \(data.component.rawValue)")
        print("📊 Status: \(data.status)")
        print("📅 Due Date: \(data.dueDate)")
        print("🧰 Parts Used: \(data.partsUsed.map { $0.partName }.joined(separator: ", "))")
        
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
        
        print("🆔 Generated Task ID: \(newTask.id)")
        print("📤 Sending to Supabase table: maintenance_tasks...")

        try await client
            .from("maintenance_tasks")
            .insert(newTask)
            .execute()

        print("✅ Maintenance task created successfully!")
        print("✅ Task: \(data.component.rawValue) for \(data.vehicleRegistrationNumber)")
        print("✅ Stored in table: maintenance_tasks")
        print("🔧 ============================================")
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
        
        // Update vehicle status if all tasks completed
        let tasks = try await fetchMaintenanceTasks()
        if let task = tasks.first(where: { $0.id == taskId }) {
            try await updateVehicleStatusAfterTaskCompletion(
                vehicleRegistration: task.vehicleRegistrationNumber
            )
        }
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

    /// Pause a task (keeps status as "In Progress" in DB, uses pausedAt to track paused state)
    public func pauseTask(taskId: UUID) async throws {
        struct TaskUpdate: Encodable {
            let pausedAt: Date = Date()
            let updatedAt: Date = Date()

            enum CodingKeys: String, CodingKey {
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

        print("✅ Task \(taskId) paused (pausedAt timestamp set)")
    }

    /// Resume a task (clears pausedAt timestamp)
    public func resumeTask(taskId: UUID) async throws {
        struct TaskUpdate: Encodable {
            let pausedAt: Date? = nil
            let updatedAt: Date = Date()

            enum CodingKeys: String, CodingKey {
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

        print("✅ Task \(taskId) resumed (pausedAt cleared)")
    }

    /// Mark task as failed
    public func failTask(taskId: UUID, reason: String) async throws {
        struct TaskUpdate: Encodable {
            let status: String = "Cancelled"  // Use Cancelled status, track failure via failedReason
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

        print("✅ Task \(taskId) marked as failed (status: Cancelled, reason: \(reason))")
    }

    /// Add a part usage to a task
    public func addPart(taskId: UUID, part: PartUsage) async throws {
        print("🔧 ========== ADDING PART TO TASK ==========")
        print("📋 Table: maintenance_tasks")
        print("🆔 Task ID: \(taskId)")
        print("🔩 Part Name: \(part.partName)")
        print("📦 Quantity: \(part.quantity)")
        print("💰 Unit Price: ₹\(part.unitPrice)")
        print("💵 Total Cost: ₹\(part.totalCost)")
        
        // Fetch current parts
        print("")
        print("📤 Step 1/3: Fetching current parts from database...")
        let tasks: [MaintenanceTask]
        do {
            tasks = try await client
                .from("maintenance_tasks")
                .select()  // Select all columns so MaintenanceTask can decode properly
                .eq("id", value: taskId)
                .execute()
                .value
            print("✅ Successfully fetched task data")
        } catch {
            print("❌ Failed to fetch task: \(error)")
            throw error
        }

        guard let existingTask = tasks.first else {
            print("❌ ERROR: Task with ID \(taskId) not found in database!")
            throw NSError(domain: "MaintenanceService", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Task not found"
            ])
        }
        
        var parts = existingTask.partsUsed
        print("📊 Current parts count: \(parts.count)")
        parts.append(part)
        print("📊 New parts count: \(parts.count)")

        print("")
        print("📤 Step 2/3: Updating parts_used in database...")
        do {
            try await client
                .from("maintenance_tasks")
                .update(["parts_used": parts])
                .eq("id", value: taskId)
                .execute()
            print("✅ Successfully updated parts_used column")
        } catch {
            print("❌ Failed to update parts: \(error)")
            throw error
        }

        // Step 3: Deduct from inventory if partId is available
        if let partId = part.partId {
            print("")
            print("📤 Step 3/3: Deducting \(part.quantity) units from inventory...")
            do {
                try await deductInventory(partId: partId, quantity: part.quantity)
                print("✅ Successfully deducted from inventory")
            } catch {
                print("⚠️ Warning: Failed to deduct from inventory: \(error)")
                // Don't throw - part was already added to task
            }
        } else {
            print("")
            print("⏭️ Step 3/3: Skipping inventory deduction (custom part, no partId)")
        }

        print("")
        print("✅ ========== PART ADDED SUCCESSFULLY ==========")
        print("✅ Part '\(part.partName)' added to task \(taskId)")
        print("✅ Table: maintenance_tasks, Column: parts_used")
        print("🔧 ============================================")
    }
    
    /// Deduct quantity from inventory
    private func deductInventory(partId: UUID, quantity: Int) async throws {
        // Fetch current inventory part
        let inventoryParts: [InventoryPart] = try await client
            .from("parts")
            .select()
            .eq("id", value: partId)
            .execute()
            .value
        
        guard let inventoryPart = inventoryParts.first else {
            throw NSError(domain: "MaintenanceService", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Inventory part not found"
            ])
        }
        
        let newQuantity = max(0, inventoryPart.quantityInStock - quantity)
        
        struct QuantityUpdate: Encodable {
            let quantityInStock: Int
            let updatedAt: Date = Date()
            
            enum CodingKeys: String, CodingKey {
                case quantityInStock = "quantity_in_stock"
                case updatedAt = "updated_at"
            }
        }
        
        let update = QuantityUpdate(quantityInStock: newQuantity)
        
        try await client
            .from("parts")
            .update(update)
            .eq("id", value: partId)
            .execute()
        
        print("✅ Inventory updated: \(inventoryPart.name) - \(inventoryPart.quantityInStock) → \(newQuantity)")
    }

    /// Remove a part usage from a task
    public func removePart(taskId: UUID, part: PartUsage) async throws {
        print("🔧 Removing part '\(part.partName)' from task \(taskId)")
        
        // Fetch current task - select all columns for proper decoding
        let tasks: [MaintenanceTask] =
            try await client
            .from("maintenance_tasks")
            .select()  // Select all columns
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
        
        // Restore inventory if partId is available
        if let partId = part.partId {
            print("📤 Restoring \(part.quantity) units to inventory...")
            do {
                try await restoreInventory(partId: partId, quantity: part.quantity)
                print("✅ Successfully restored to inventory")
            } catch {
                print("⚠️ Warning: Failed to restore to inventory: \(error)")
            }
        }
    }
    
    /// Restore quantity to inventory
    private func restoreInventory(partId: UUID, quantity: Int) async throws {
        let inventoryParts: [InventoryPart] = try await client
            .from("parts")
            .select()
            .eq("id", value: partId)
            .execute()
            .value
        
        guard let inventoryPart = inventoryParts.first else {
            throw NSError(domain: "MaintenanceService", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Inventory part not found"
            ])
        }
        
        let newQuantity = inventoryPart.quantityInStock + quantity
        
        struct QuantityUpdate: Encodable {
            let quantityInStock: Int
            let updatedAt: Date = Date()
            
            enum CodingKeys: String, CodingKey {
                case quantityInStock = "quantity_in_stock"
                case updatedAt = "updated_at"
            }
        }
        
        let update = QuantityUpdate(quantityInStock: newQuantity)
        
        try await client
            .from("parts")
            .update(update)
            .eq("id", value: partId)
            .execute()
        
        print("✅ Inventory restored: \(inventoryPart.name) - \(inventoryPart.quantityInStock) → \(newQuantity)")
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
        
        // Update vehicle status if all tasks completed
        let tasks = try await fetchMaintenanceTasks()
        if let task = tasks.first(where: { $0.id == taskId }) {
            try await updateVehicleStatusAfterTaskCompletion(
                vehicleRegistration: task.vehicleRegistrationNumber
            )
        }
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

    // MARK: - Inventory Operations

    /// Fetch all inventory parts
    public func fetchInventoryParts() async throws -> [InventoryPart] {
        let parts: [InventoryPart] =
            try await client
            .from("parts")
            .select()
            .execute()
            .value

        print("✅ Fetched \(parts.count) inventory parts from Supabase")
        return parts
    }

    /// Add a new inventory part
    public func addInventoryPart(_ part: InventoryPart) async throws {
        try await client
            .from("parts")
            .insert(part)
            .execute()

        print("✅ Inventory part added: \(part.name)")
    }

    /// Update an inventory part
    public func updateInventoryPart(_ part: InventoryPart) async throws {
        try await client
            .from("parts")
            .update(part)
            .eq("id", value: part.id)
            .execute()

        print("✅ Inventory part updated: \(part.name)")
    }

    /// Delete an inventory part
    public func deleteInventoryPart(partId: UUID) async throws {
        try await client
            .from("parts")
            .delete()
            .eq("id", value: partId)
            .execute()

        print("✅ Inventory part \(partId) deleted")
    }

    // MARK: - Alerts Operations

    /// Fetch all maintenance alerts
    public func fetchAlerts() async throws -> [MaintenanceAlert] {
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
    public func markAlertAsRead(alertId: UUID) async throws {
        try await client
            .from("maintenance_alerts")
            .update(["is_read": true])
            .eq("id", value: alertId)
            .execute()

        print("✅ Alert \(alertId) marked as read")
    }

    /// Delete an alert
    public func deleteAlert(alertId: UUID) async throws {
        try await client
            .from("maintenance_alerts")
            .delete()
            .eq("id", value: alertId)
            .execute()

        print("✅ Alert \(alertId) deleted")
    }
    
    // MARK: - Task Reschedule & Cancel (Direct Action)
    
    /// Reschedule a task (direct action)
    public func rescheduleTask(taskId: UUID, newDate: Date, reason: String) async throws {
        struct TaskUpdate: Encodable {
            let dueDate: Date
            let updatedAt: Date = Date()
            
            enum CodingKeys: String, CodingKey {
                case dueDate = "due_date"
                case updatedAt = "updated_at"
            }
        }
        
        let update = TaskUpdate(dueDate: newDate)
        
        try await client
            .from("maintenance_tasks")
            .update(update)
            .eq("id", value: taskId)
            .execute()
        
        // Create manager alert
        try await createManagerAlert(
            title: "Task Rescheduled",
            message: "Task has been rescheduled to \(formattedDate(newDate)). Reason: \(reason)",
            taskId: taskId
        )
        
        print("✅ Task \(taskId) rescheduled to \(newDate)")
    }
    
    /// Cancel a task (direct action)
    public func cancelTask(taskId: UUID, reason: String) async throws {
        struct TaskUpdate: Encodable {
            let status: String = "Cancelled"
            let isLocked: Bool = true
            let updatedAt: Date = Date()
            
            enum CodingKeys: String, CodingKey {
                case status
                case isLocked = "is_locked"
                case updatedAt = "updated_at"
            }
        }
        
        let update = TaskUpdate()
        
        try await client
            .from("maintenance_tasks")
            .update(update)
            .eq("id", value: taskId)
            .execute()
        
        // Create manager alert
        try await createManagerAlert(
            title: "Task Cancelled",
            message: "Task has been cancelled. Reason: \(reason)",
            taskId: taskId
        )
        
        print("✅ Task \(taskId) cancelled")
    }
    
    /// Create a manager alert
    private func createManagerAlert(title: String, message: String, taskId: UUID) async throws {
        struct AlertInsert: Encodable {
            let title: String
            let message: String
            let taskId: UUID
            let type: String = "info"
            let createdAt: Date = Date()
            
            enum CodingKeys: String, CodingKey {
                case title
                case message
                case taskId = "task_id"
                case type
                case createdAt = "created_at"
            }
        }
        
        let alert = AlertInsert(title: title, message: message, taskId: taskId)
        
        try await client
            .from("maintenance_alerts")
            .insert(alert)
            .execute()
        
        print("✅ Manager alert created: \(title)")
    }
    
    /// Format date for display
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Vehicle Status Management
    
    /// Check if all tasks for a vehicle are completed and update vehicle status
    private func updateVehicleStatusAfterTaskCompletion(vehicleRegistration: String) async throws {
        // 1. Fetch all tasks for this vehicle
        let tasks = try await fetchMaintenanceTasks()
        let vehicleTasks = tasks.filter { $0.vehicleRegistrationNumber == vehicleRegistration }
        
        // 2. Check if all tasks are completed or cancelled
        let allCompleted = vehicleTasks.allSatisfy { 
            $0.status == "Completed" || $0.status == "Cancelled" 
        }
        
        // 3. Update vehicle status to Active if all tasks are done
        if allCompleted && !vehicleTasks.isEmpty {
            try await updateVehicleStatus(registration: vehicleRegistration, status: "Active")
            print("✅ Vehicle \(vehicleRegistration) status updated to Active (all tasks completed)")
        } else {
            print("ℹ️ Vehicle \(vehicleRegistration) still has pending tasks")
        }
    }
    
    /// Update vehicle status in database
    public func updateVehicleStatus(registration: String, status: String) async throws {
        struct VehicleStatusUpdate: Encodable {
            let status: String
            let updatedAt: Date = Date()
            
            enum CodingKeys: String, CodingKey {
                case status
                case updatedAt = "updated_at"
            }
        }
        
        let update = VehicleStatusUpdate(status: status)
        
        try await client
            .from("vehicles")
            .update(update)
            .eq("registration_number", value: registration)
            .execute()
        
        print("✅ Vehicle \(registration) status updated to \(status)")
    }
    
    /// Fetch driver by ID for alerts
    func fetchDriverForAlert(driverId: UUID) async throws -> Driver? {
        let driver: Driver? = try await client
            .from("drivers")
            .select()
            .eq("id", value: driverId)
            .single()
            .execute()
            .value
        
        return driver
    }
}
