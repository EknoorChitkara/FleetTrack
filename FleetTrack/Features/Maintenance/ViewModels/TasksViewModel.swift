//
//  TasksViewModel.swift
//  FleetTrack
//
//  Created for Maintenance Module - Task Management
//

import Combine
import Foundation
import SwiftUI

// MARK: - Filter Options

public enum DateFilterOption: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case overdue = "Overdue"
}

// MARK: - Sort Options

public enum TaskSortOption: String, CaseIterable {
    case dueDate = "Due Date"
    case priority = "Priority"
    case vehicle = "Vehicle"
    case status = "Status"
}

// MARK: - Tasks View Model

public class TasksViewModel: ObservableObject {

    // MARK: - Shared Instance

    static let shared = TasksViewModel()

    // MARK: - Published Properties

    @Published var allTasks: [MaintenanceTask] = []
    @Published var filteredTasks: [MaintenanceTask] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Filter State

    @Published var dateFilter: DateFilterOption = .all
    @Published var selectedPriorities: Set<MaintenancePriority> = []
    @Published var selectedVehicleTypes: Set<VehicleType> = []
    @Published var selectedStatuses: Set<String> = []
    @Published var sortOption: TaskSortOption = .dueDate

    // MARK: - Computed Properties

    var availableVehicles: [String] {
        let vehicles = Set(allTasks.map { $0.vehicleRegistrationNumber })
        return Array(vehicles).sorted()
    }

    var activeFilterCount: Int {
        var count = 0
        if dateFilter != .all { count += 1 }
        if !selectedPriorities.isEmpty { count += 1 }
        if !selectedVehicleTypes.isEmpty { count += 1 }
        if !selectedStatuses.isEmpty { count += 1 }
        return count
    }

    var hasActiveFilters: Bool {
        activeFilterCount > 0
    }

    // Group tasks by status
    var pendingTasks: [MaintenanceTask] {
        filteredTasks.filter { $0.status == "Pending" }
    }

    var inProgressTasks: [MaintenanceTask] {
        filteredTasks.filter { $0.status == "In Progress" && !$0.isPaused }
    }

    var pausedTasks: [MaintenanceTask] {
        filteredTasks.filter { $0.isPaused }
    }

    var completedTasks: [MaintenanceTask] {
        filteredTasks.filter { $0.status == "Completed" }
    }

    var failedTasks: [MaintenanceTask] {
        filteredTasks.filter { $0.status == "Failed" }
    }

    // MARK: - Initialization

    init() {
        // Note: Initial load is handled by the view's .task modifier
    }

    // MARK: - Data Loading

    @MainActor
    func loadTasks() async {
        // Prevent concurrent loading
        guard !isLoading else {
            print("⏭️ Skipping loadTasks - already loading")
            return
        }
        
        isLoading = true
        errorMessage = nil

        // Fetch real data from Supabase
        do {
            let tasks = try await MaintenanceService.shared.fetchMaintenanceTasks()
            self.allTasks = tasks
            applyFiltersAndSort()
            isLoading = false
            print("✅ Loaded \(tasks.count) maintenance tasks from Supabase")
        } catch {
            self.errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            self.isLoading = false
            print("❌ Error loading tasks: \(error)")
        }
    }

    // MARK: - Filtering and Sorting

    func applyFiltersAndSort() {
        var tasks = allTasks

        // Apply date filter
        tasks = filterByDate(tasks)

        // Apply priority filter
        if !selectedPriorities.isEmpty {
            tasks = tasks.filter { selectedPriorities.contains($0.priority) }
        }

        // Apply vehicle type filter (would need vehicle data)
        // Skipping for now as we don't have vehicle type in task

        // Apply status filter
        if !selectedStatuses.isEmpty {
            tasks = tasks.filter { selectedStatuses.contains($0.status) }
        }

        // Apply sorting
        tasks = sortTasks(tasks)

        filteredTasks = tasks
    }

    private func filterByDate(_ tasks: [MaintenanceTask]) -> [MaintenanceTask] {
        let calendar = Calendar.current
        let now = Date()

        switch dateFilter {
        case .all:
            return tasks

        case .today:
            return tasks.filter { calendar.isDateInToday($0.dueDate) }

        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? now
            return tasks.filter { $0.dueDate >= startOfWeek && $0.dueDate < endOfWeek }

        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? now
            return tasks.filter { $0.dueDate >= startOfMonth && $0.dueDate < endOfMonth }

        case .overdue:
            return tasks.filter { $0.isOverdue }
        }
    }

    private func sortTasks(_ tasks: [MaintenanceTask]) -> [MaintenanceTask] {
        switch sortOption {
        case .dueDate:
            return tasks.sorted { $0.dueDate < $1.dueDate }

        case .priority:
            return tasks.sorted { task1, task2 in
                let priorityOrder: [MaintenancePriority] = [.high, .medium, .low]
                let index1 = priorityOrder.firstIndex(of: task1.priority) ?? 999
                let index2 = priorityOrder.firstIndex(of: task2.priority) ?? 999
                return index1 < index2
            }

        case .vehicle:
            return tasks.sorted { $0.vehicleRegistrationNumber < $1.vehicleRegistrationNumber }

        case .status:
            return tasks.sorted { $0.status < $1.status }
        }
    }

    // MARK: - Filter Actions

    func updateDateFilter(_ filter: DateFilterOption) {
        dateFilter = filter
        applyFiltersAndSort()
    }

    func togglePriority(_ priority: MaintenancePriority) {
        if selectedPriorities.contains(priority) {
            selectedPriorities.remove(priority)
        } else {
            selectedPriorities.insert(priority)
        }
        applyFiltersAndSort()
    }

    func toggleStatus(_ status: String) {
        if selectedStatuses.contains(status) {
            selectedStatuses.remove(status)
        } else {
            selectedStatuses.insert(status)
        }
        applyFiltersAndSort()
    }

    func updateSortOption(_ option: TaskSortOption) {
        sortOption = option
        applyFiltersAndSort()
    }

    func clearAllFilters() {
        dateFilter = .all
        selectedPriorities.removeAll()
        selectedVehicleTypes.removeAll()
        selectedStatuses.removeAll()
        applyFiltersAndSort()
    }

    // MARK: - Task Updates

    public func updateTask(_ updatedTask: MaintenanceTask) {
        if let index = allTasks.firstIndex(where: { $0.id == updatedTask.id }) {
            allTasks[index] = updatedTask
            applyFiltersAndSort()
            print("✅ Task updated in list: \(updatedTask.id)")
        }
    }

    // MARK: - Refresh

    @MainActor
    func refreshData() async {
        await loadTasks()
    }
}
