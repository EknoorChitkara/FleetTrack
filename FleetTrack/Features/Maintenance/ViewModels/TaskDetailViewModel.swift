//
//  TaskDetailViewModel.swift
//  FleetTrack
//
//  Created for Maintenance Module - Task Management
//

import Foundation
import Combine

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
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Update task locally
        task.status = "In Progress"
        task.startedAt = Date()
        
        // Update in shared view model
        TasksViewModel.shared.updateTask(task)
        
        isLoading = false
        print("✅ Task started")
        
        /* Uncomment for real implementation:
        do {
            try await MaintenanceService.shared.startTask(taskId: task.id, userId: currentUserId)
            task.status = "In Progress"
            task.startedAt = Date()
            TasksViewModel.shared.updateTask(task)
        } catch {
            errorMessage = "Failed to start task: \(error.localizedDescription)"
        }
        isLoading = false
        */
    }
    
    func pauseTask() async {
        isLoading = true
        errorMessage = nil
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        task.status = "Paused"
        task.pausedAt = Date()
        
        // Update in shared view model
        TasksViewModel.shared.updateTask(task)
        
        isLoading = false
        print("✅ Task paused")
    }
    
    func resumeTask() async {
        isLoading = true
        errorMessage = nil
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        task.status = "In Progress"
        task.pausedAt = nil
        
        // Update in shared view model
        TasksViewModel.shared.updateTask(task)
        
        isLoading = false
        print("✅ Task resumed")
    }
    
    func completeTask(repairDescription: String, laborHours: Double) async {
        isLoading = true
        errorMessage = nil
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        task.status = "Completed"
        task.completedDate = Date()
        task.isLocked = true
        task.repairDescription = repairDescription
        task.laborHours = laborHours
        
        // Update in shared view model
        TasksViewModel.shared.updateTask(task)
        
        isLoading = false
        showingCompletionSheet = false
        print("✅ Task completed and locked")
    }
    
    func failTask(reason: String) async {
        isLoading = true
        errorMessage = nil
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        task.status = "Failed"
        task.completedDate = Date()
        task.isLocked = true
        task.failedReason = reason
        
        // Update in shared view model
        TasksViewModel.shared.updateTask(task)
        
        isLoading = false
        showingFailureSheet = false
        print("✅ Task marked as failed")
    }
    
    // MARK: - Parts Management
    
    func addPart(_ part: PartUsage) async {
        isLoading = true
        errorMessage = nil
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        task.partsUsed.append(part)
        
        // Update in shared view model
        TasksViewModel.shared.updateTask(task)
        
        isLoading = false
        showingAddPartSheet = false
        print("✅ Part added: \(part.partName)")
    }
    
    func removePart(at index: Int) async {
        isLoading = true
        errorMessage = nil
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        let removedPart = task.partsUsed[index]
        task.partsUsed.remove(at: index)
        
        // Update in shared view model
        TasksViewModel.shared.updateTask(task)
        
        isLoading = false
        print("✅ Part removed: \(removedPart.partName)")
    }
    
    // MARK: - Repair Log Updates
    
    func updateRepairLog(description: String, laborHours: Double, partsUsed: [PartUsage]) async {
        isLoading = true
        errorMessage = nil
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Update task
        task.repairDescription = description
        task.laborHours = laborHours
        task.partsUsed = partsUsed
        
        // Update in shared view model
        TasksViewModel.shared.updateTask(task)
        
        isLoading = false
        showingEditRepairLogSheet = false
        print("✅ Repair log updated")
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
