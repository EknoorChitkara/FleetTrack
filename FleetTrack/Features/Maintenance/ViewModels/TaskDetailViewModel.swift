//
//  TaskDetailViewModel.swift
//  FleetTrack
//
//  Created for Maintenance Module - Task Management
//

import Combine
import Foundation

@MainActor
class TaskDetailViewModel: ObservableObject {

    @Published var task: MaintenanceTask
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingCompletionSheet: Bool = false
    @Published var showingFailureSheet: Bool = false
    @Published var showingRescheduleSheet: Bool = false
    @Published var showingCancelSheet: Bool = false
    @Published var showingEditRepairLogSheet: Bool = false
    @Published var showingAddPartSheet: Bool = false

    init(task: MaintenanceTask) {
        self.task = task
    }

    // MARK: - Status Actions

    func startTask() async {
        isLoading = true
        errorMessage = nil

        do {
            try await MaintenanceService.shared.startTask(taskId: task.id)
            task.status = "In Progress"
            task.startedAt = Date()
            TasksViewModel.shared.updateTask(task)
            print("✅ Task started via Service")
        } catch {
            errorMessage = "Failed to start task: \(error.localizedDescription)"
            print("❌ Error starting task: \(error)")
        }
        isLoading = false
    }

    func pauseTask() async {
        isLoading = true
        errorMessage = nil

        do {
            try await MaintenanceService.shared.pauseTask(taskId: task.id)
            // Keep status as "In Progress" for database compatibility
            // But set pausedAt to indicate paused state
            task.pausedAt = Date()
            task.updatedAt = Date()
            
            // Update shared task list
            TasksViewModel.shared.updateTask(task)
            
            // Force UI refresh
            objectWillChange.send()
            
            print("✅ Task paused via Service")
        } catch {
            errorMessage = "Failed to pause task: \(error.localizedDescription)"
            print("❌ Error pausing task: \(error)")
        }
        isLoading = false
    }

    func resumeTask() async {
        isLoading = true
        errorMessage = nil

        do {
            try await MaintenanceService.shared.resumeTask(taskId: task.id)
            // Status remains "In Progress"
            task.pausedAt = nil
            TasksViewModel.shared.updateTask(task)
            print("✅ Task resumed via Service")
        } catch {
            errorMessage = "Failed to resume task: \(error.localizedDescription)"
            print("❌ Error resuming task: \(error)")
        }
        isLoading = false
    }

    func completeTask(repairDescription: String, laborHours: Double) async {
        isLoading = true
        errorMessage = nil

        do {
            try await MaintenanceService.shared.completeTaskWithRepairLog(
                taskId: task.id,
                repairDescription: repairDescription,
                laborHours: laborHours,
                partsUsed: task.partsUsed
            )
            task.status = "Completed"
            task.completedDate = Date()
            task.isLocked = true
            task.repairDescription = repairDescription
            task.laborHours = laborHours
            TasksViewModel.shared.updateTask(task)
            showingCompletionSheet = false
            
            // Notify dashboard to refresh
            NotificationCenter.default.post(name: NSNotification.Name("TaskCompleted"), object: nil)
            
            print("✅ Task completed via Service")
        } catch {
            errorMessage = "Failed to complete task: \(error.localizedDescription)"
            print("❌ Error completing task: \(error)")
        }
        isLoading = false
    }

    func failTask(reason: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await MaintenanceService.shared.failTask(taskId: task.id, reason: reason)
            task.status = "Failed"
            task.completedDate = Date()
            task.isLocked = true
            task.failedReason = reason
            TasksViewModel.shared.updateTask(task)
            showingFailureSheet = false
            print("✅ Task failed via Service")
        } catch {
            errorMessage = "Failed to mark task as failed: \(error.localizedDescription)"
            print("❌ Error failing task: \(error)")
        }
        isLoading = false
    }

    // MARK: - Parts Management

    func addPart(_ part: PartUsage) async {
        isLoading = true
        errorMessage = nil

        do {
            try await MaintenanceService.shared.addPart(taskId: task.id, part: part)
            task.partsUsed.append(part)
            TasksViewModel.shared.updateTask(task)
            showingAddPartSheet = false
            print("✅ Part added via Service")
        } catch {
            errorMessage = "Failed to add part: \(error.localizedDescription)"
            print("❌ Error adding part: \(error)")
        }
        isLoading = false
    }

    func removePart(at index: Int) async {
        isLoading = true
        errorMessage = nil

        let part = task.partsUsed[index]
        do {
            try await MaintenanceService.shared.removePart(taskId: task.id, part: part)
            task.partsUsed.remove(at: index)
            TasksViewModel.shared.updateTask(task)
            print("✅ Part removed via Service")
        } catch {
            errorMessage = "Failed to remove part: \(error.localizedDescription)"
            print("❌ Error removing part: \(error)")
        }
        isLoading = false
    }

    // MARK: - Repair Log Updates

    func updateRepairLog(description: String, laborHours: Double, partsUsed: [PartUsage]) async {
        isLoading = true
        errorMessage = nil

        do {
            try await MaintenanceService.shared.updateRepairLog(
                taskId: task.id,
                repairDescription: description,
                laborHours: laborHours,
                partsUsed: partsUsed
            )
            task.repairDescription = description
            task.laborHours = laborHours
            task.partsUsed = partsUsed
            TasksViewModel.shared.updateTask(task)
            showingEditRepairLogSheet = false
            print("✅ Repair log updated via Service")
        } catch {
            errorMessage = "Failed to update repair log: \(error.localizedDescription)"
            print("❌ Error updating repair log: \(error)")
        }
        isLoading = false
    }

    // MARK: - Reschedule & Cancel Requests

    func requestReschedule(newDate: Date, reason: String) async {
        isLoading = true
        errorMessage = nil

        try? await Task.sleep(nanoseconds: 500_000_000)

        // In real app, this would create a RescheduleRequest in database
        print("📅 Reschedule request submitted:")
        print("  New Date: \(newDate)")
        print("  Reason: \(reason)")
        print("  Status: Pending Approval")

        isLoading = false
        showingRescheduleSheet = false

        // Show success message (in real app, would update UI)
        errorMessage = nil
    }

    func requestCancellation(reason: String) async {
        isLoading = true
        errorMessage = nil

        try? await Task.sleep(nanoseconds: 500_000_000)

        // In real app, this would create a CancelRequest in database
        print("❌ Cancellation request submitted:")
        print("  Reason: \(reason)")
        print("  Status: Pending Approval")

        isLoading = false
        showingCancelSheet = false

        // Show success message
        errorMessage = nil
    }
}
