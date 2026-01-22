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
    @Published var assignedDriver: Driver?
    @Published var assignedVehicle: Vehicle?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showingCompletionSheet: Bool = false
    @Published var showingCompletionConfirmation: Bool = false
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
    
    // MARK: - Driver Loading
    
    func loadAssignedDriver() async {
        do {
            // Step 1: Fetch the vehicle using registration number
            guard let vehicle = try await MaintenanceService.shared.fetchVehicle(byRegistration: task.vehicleRegistrationNumber) else {
                print("⚠️ Vehicle not found: \(task.vehicleRegistrationNumber)")
                assignedDriver = nil
                assignedVehicle = nil
                return
            }
            
            // Store vehicle for display
            assignedVehicle = vehicle
            print("✅ Loaded vehicle: \(vehicle.manufacturer) \(vehicle.model) (\(vehicle.registrationNumber))")
            
            // Step 2: Get the assigned driver ID from the vehicle
            guard let driverId = vehicle.assignedDriverId else {
                print("ℹ️ No driver assigned to vehicle: \(task.vehicleRegistrationNumber)")
                assignedDriver = nil
                return
            }
            
            // Step 3: Fetch the driver details
            assignedDriver = try await MaintenanceService.shared.fetchDriver(byId: driverId)
            if let driver = assignedDriver {
                print("✅ Loaded driver: \(driver.fullName) for vehicle \(task.vehicleRegistrationNumber)")
                print("   📞 Phone: \(driver.phoneNumber ?? "nil")")
                print("   📧 Email: \(driver.email)")
            }
        } catch {
            print("❌ Error loading driver: \(error)")
            assignedDriver = nil
            assignedVehicle = nil
        }
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

    func rescheduleTask(newDate: Date, reason: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Update task due date
            try await MaintenanceService.shared.rescheduleTask(
                taskId: task.id,
                newDueDate: newDate,
                reason: reason
            )
            
            task.dueDate = newDate
            TasksViewModel.shared.updateTask(task)
            
            // Create alert for fleet manager
            try await MaintenanceService.shared.createManagerAlert(
                title: "Task Rescheduled",
                message: "Task '\(task.description ?? "Maintenance Task")' for vehicle \(task.vehicleRegistrationNumber) has been rescheduled to \(formattedDate(newDate)). Reason: \(reason)",
                type: .maintenance
            )
            
            showingRescheduleSheet = false
            print("✅ Task rescheduled successfully")
        } catch {
            errorMessage = "Failed to reschedule task: \(error.localizedDescription)"
            print("❌ Error rescheduling task: \(error)")
        }
        isLoading = false
    }

    func cancelTask(reason: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Cancel the task
            try await MaintenanceService.shared.cancelTask(
                taskId: task.id,
                reason: reason
            )
            
            task.status = "Cancelled"
            task.isLocked = true
            TasksViewModel.shared.updateTask(task)
            
            // Create alert for fleet manager
            try await MaintenanceService.shared.createManagerAlert(
                title: "Task Cancelled",
                message: "Task '\(task.description ?? "Maintenance Task")' for vehicle \(task.vehicleRegistrationNumber) has been cancelled. Reason: \(reason)",
                type: .maintenance
            )
            
            showingCancelSheet = false
            print("✅ Task cancelled successfully")
        } catch {
            errorMessage = "Failed to cancel task: \(error.localizedDescription)"
            print("❌ Error cancelling task: \(error)")
        }
        isLoading = false
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
