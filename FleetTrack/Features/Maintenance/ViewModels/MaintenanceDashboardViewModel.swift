//
//  MaintenanceDashboardViewModel.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import Combine
import Foundation

class MaintenanceDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    // Old properties - commented out for now, will be implemented later
    // @Published var stats: MaintenanceDashboardStats
    // @Published var todaysSchedule: [WorkOrder]
    // @Published var priorityTasks: [WorkOrder]
    @Published var alerts: [MaintenanceAlert] = []
    @Published var isLoading: Bool = false

    // New properties for updated dashboard design
    @Published var currentUser: User
    @Published var pendingTasksCount: Int = 0
    @Published var inProgressTasksCount: Int = 0
    @Published var maintenanceSummary: MaintenanceSummary
    @Published var highPriorityMaintenanceTasks: [MaintenanceTask] = []
    @Published var completedTasks: [MaintenanceTask] = []

    // MARK: - Error Handling

    @Published var errorMessage: String?

    // MARK: - Initialization

    init(user: User) {
        // Initialize new dashboard properties
        // Using the existing User model from Authentication
        self.currentUser = user
        self.maintenanceSummary = MaintenanceSummary(
            completedTasksThisMonth: 0,
            averageCompletionTimeHours: 0.0
        )

        // Note: Initial load is handled by the view's .task modifier
    }

    // MARK: - Data Loading

    @MainActor
    func loadData() async {
        // Prevent concurrent loading
        guard !isLoading else {
            print("⏭️ Skipping loadData - already loading")
            return
        }
        
        isLoading = true
        do {
            // Fetch tasks from Supabase
            let tasks = try await MaintenanceService.shared.fetchMaintenanceTasks()

            // Filter high priority pending tasks
            self.highPriorityMaintenanceTasks =
                tasks
                .filter { $0.priority == .high && $0.status == "Pending" }
                .sorted { $0.dueDate < $1.dueDate }

            // Get most recent completed tasks (limit to 3)
            self.completedTasks =
                tasks
                .filter { $0.status == "Completed" }
                .sorted {
                    ($0.completedDate ?? Date.distantPast) > ($1.completedDate ?? Date.distantPast)
                }
                .prefix(3)
                .map { $0 }

            // Calculate task counts
            self.pendingTasksCount = tasks.filter { $0.status == "Pending" }.count
            self.inProgressTasksCount = tasks.filter { $0.status == "In Progress" }.count

            // Fetch alerts from Supabase
            self.alerts = try await MaintenanceService.shared.fetchAlerts()

            self.isLoading = false
            print("✅ Maintenance Data Loaded: \(tasks.count) tasks, \(self.alerts.count) alerts")
        } catch {
            self.errorMessage = "Failed to load maintenance data: \(error.localizedDescription)"
            self.isLoading = false
            print("❌ Error loading maintenance data: \(error)")
        }
    }

    // MARK: - Actions

    func addMaintenanceTask(_ data: MaintenanceTaskCreationData) {
        isLoading = true
        Task { @MainActor in
            do {
                print("🚀 MaintenanceDashboardViewModel: Attempting to add maintenance task...")
                try await MaintenanceService.shared.addMaintenanceTask(data)
                print("🎉 MaintenanceDashboardViewModel: Task added successfully, reloading data...")

                // Reload data to reflect changes
                await loadData()
            } catch {
                print("❌ ============================================")
                print("❌ ERROR in MaintenanceDashboardViewModel.addMaintenanceTask")
                print("❌ Vehicle: \(data.vehicleRegistrationNumber)")
                print("❌ Component: \(data.component.rawValue)")
                print("❌ Error: \(error.localizedDescription)")
                print("❌ Full Error: \(error)")
                print("❌ ============================================")
                
                self.errorMessage = "Failed to add maintenance task: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ Error adding maintenance task: \(error)")
            }
        }
    }

    func updateTaskStatus(taskId: UUID, status: String) {
        Task { @MainActor in
            do {
                try await MaintenanceService.shared.updateTaskStatus(taskId: taskId, status: status)
                await loadData()
            } catch {
                self.errorMessage = "Failed to update task status: \(error.localizedDescription)"
                print("❌ Error updating task status: \(error)")
            }
        }
    }

    func completeTask(taskId: UUID) {
        Task { @MainActor in
            do {
                try await MaintenanceService.shared.completeTask(taskId: taskId)
                await loadData()
            } catch {
                self.errorMessage = "Failed to complete task: \(error.localizedDescription)"
                print("❌ Error completing task: \(error)")
            }
        }
    }

    @MainActor
    func refreshData() async {
        await loadData()
    }
}
