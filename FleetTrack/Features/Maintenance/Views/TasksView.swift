//
//  TasksView.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import SwiftUI

struct TasksView: View {
    @ObservedObject var viewModel = TasksViewModel.shared
    @State private var showingFilterSheet = false
    @State private var showingSortSheet = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Filter and Sort Bar
                filterSortBar
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.filteredTasks.isEmpty {
                    emptyStateView
                } else {
                    taskListView
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            TaskFilterSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingSortSheet) {
            TaskSortSheet(viewModel: viewModel)
        }
        .refreshable {
            await viewModel.refreshData()
        }
        .task {
            await viewModel.loadTasks()
        }
        .onAppear {
            if !viewModel.isLoading {
                InAppVoiceManager.shared.speak(voiceSummary())
            }
        }
        .onChange(of: viewModel.isLoading) { loading in
            if !loading {
                InAppVoiceManager.shared.speak(voiceSummary())
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tasks")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                
                if !viewModel.filteredTasks.isEmpty {
                    Text("\(viewModel.filteredTasks.count) task\(viewModel.filteredTasks.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, AppTheme.spacing.md)
        .padding(.vertical, AppTheme.spacing.sm)
    }
    
    // MARK: - Filter and Sort Bar
    
    private var filterSortBar: some View {
        HStack(spacing: AppTheme.spacing.sm) {
            // Filter Button
            Button(action: {
                showingFilterSheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle\(viewModel.hasActiveFilters ? ".fill" : "")")
                        .font(.system(size: 16))
                    
                    Text("Filter")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if viewModel.activeFilterCount > 0 {
                        Text("\(viewModel.activeFilterCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(width: 16, height: 16)
                            .background(AppTheme.accentPrimary)
                            .clipShape(Circle())
                    }
                }
                .foregroundColor(viewModel.hasActiveFilters ? AppTheme.accentPrimary : AppTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.backgroundSecondary)
                .cornerRadius(AppTheme.cornerRadius.medium)
            }
            .accessibilityLabel("Filter tasks\(viewModel.activeFilterCount > 0 ? ", \(viewModel.activeFilterCount) active" : "")")
            .accessibilityHint("Shows options to filter by status, priority, and component")
            .accessibilityIdentifier("maintenance_tasks_filter_button")
            
            // Sort Button
            Button(action: {
                showingSortSheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 16))
                    
                    Text("Sort: \(viewModel.sortOption.rawValue)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(AppTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.backgroundSecondary)
                .cornerRadius(AppTheme.cornerRadius.medium)
            }
            .accessibilityLabel("Sort tasks: \(viewModel.sortOption.rawValue)")
            .accessibilityHint("Shows options to sort by date, priority, or ID")
            .accessibilityIdentifier("maintenance_tasks_sort_button")
            
            Spacer()
            
            // Clear Filters Button
            if viewModel.hasActiveFilters {
                Button(action: {
                    viewModel.clearAllFilters()
                }) {
                    Text("Clear")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.accentPrimary)
                }
                .accessibilityLabel("Clear all filters")
                .accessibilityIdentifier("maintenance_tasks_clear_filters")
            }
        }
        .padding(.horizontal, AppTheme.spacing.md)
        .padding(.vertical, AppTheme.spacing.sm)
    }
    
    // MARK: - Task List View
    
    private var taskListView: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.spacing.md) {
                // Pending Tasks
                if !viewModel.pendingTasks.isEmpty {
                    taskSection(
                        title: "Pending",
                        count: viewModel.pendingTasks.count,
                        tasks: viewModel.pendingTasks,
                        color: AppTheme.statusWarning
                    )
                }
                
                // In Progress Tasks
                if !viewModel.inProgressTasks.isEmpty {
                    taskSection(
                        title: "In Progress",
                        count: viewModel.inProgressTasks.count,
                        tasks: viewModel.inProgressTasks,
                        color: AppTheme.accentPrimary
                    )
                }
                
                // Paused Tasks
                if !viewModel.pausedTasks.isEmpty {
                    taskSection(
                        title: "Paused",
                        count: viewModel.pausedTasks.count,
                        tasks: viewModel.pausedTasks,
                        color: AppTheme.statusIdle
                    )
                }
                
                // Completed Tasks
                if !viewModel.completedTasks.isEmpty {
                    taskSection(
                        title: "Completed",
                        count: viewModel.completedTasks.count,
                        tasks: viewModel.completedTasks,
                        color: AppTheme.statusActiveText
                    )
                }
                
                // Failed Tasks
                if !viewModel.failedTasks.isEmpty {
                    taskSection(
                        title: "Failed",
                        count: viewModel.failedTasks.count,
                        tasks: viewModel.failedTasks,
                        color: AppTheme.statusError
                    )
                }
            }
            .padding(.horizontal, AppTheme.spacing.md)
            .padding(.vertical, AppTheme.spacing.sm)
        }
    }
    
    private func taskSection(title: String, count: Int, tasks: [MaintenanceTask], color: Color) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
            // Section Header
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                    .accessibilityAddTraits(.isHeader)
                
                Text("(\(count))")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(.horizontal, AppTheme.spacing.xs)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title) section, \(count) tasks")
            .accessibilityIdentifier("maintenance_tasks_section_\(title.lowercased().replacingOccurrences(of: " ", with: "_"))")
            
            // Task Items
            ForEach(tasks) { task in
                NavigationLink(destination: TaskDetailView(task: task)) {
                    TaskListItem(task: task)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: AppTheme.spacing.md) {
            ProgressView()
                .tint(AppTheme.accentPrimary)
                .scaleEffect(1.2)
            
            Text("Loading tasks...")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: AppTheme.spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.statusError)
            
            Text("Error Loading Tasks")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.spacing.xl)
            
            Button(action: {
                Task {
                    await viewModel.refreshData()
                }
            }) {
                Text("Retry")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.accentPrimary)
                    .cornerRadius(AppTheme.cornerRadius.medium)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.spacing.md) {
            Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle" : "clipboard")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.iconDefault)
            
            Text(viewModel.hasActiveFilters ? "No Matching Tasks" : "No Tasks Available")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            Text(viewModel.hasActiveFilters ? "Try adjusting your filters to see more results." : "There are no maintenance tasks at the moment.")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.spacing.xl)
            
            if viewModel.hasActiveFilters {
                Button(action: {
                    viewModel.clearAllFilters()
                }) {
                    Text("Clear Filters")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppTheme.accentPrimary)
                        .cornerRadius(AppTheme.cornerRadius.medium)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - InAppVoiceReadable
extension TasksView: InAppVoiceReadable {
    func voiceSummary() -> String {
        if viewModel.isLoading { return "Loading tasks..." }
        
        var summary = "Maintenance Tasks. "
        
        if viewModel.pendingTasks.isEmpty && viewModel.inProgressTasks.isEmpty {
            summary += "No active tasks. "
        } else {
            summary += "You have \(viewModel.pendingTasks.count) pending and \(viewModel.inProgressTasks.count) in-progress tasks. "
        }
        
        // Read top priority task if exists
        if let topTask = viewModel.pendingTasks.first(where: { $0.priority == .high }) {
            let taskTitle = topTask.description ?? "\(topTask.component.rawValue) check for \(topTask.vehicleRegistrationNumber)"
            summary += "High priority task: \(taskTitle). "
        }
        
        // Completed Tasks (Added based on user request)
        let completed = viewModel.completedTasks
        if !completed.isEmpty {
            summary += "Completed Tasks: "
            // Read up to 5 completed tasks to avoid too much verbosity, or all if reasonable
            for task in completed.prefix(5) {
                let description = task.description ?? "\(task.component.rawValue) task"
                summary += "Completed \(description) for \(task.vehicleRegistrationNumber). "
            }
        }
        
        return summary
    }
}

#Preview {
    NavigationView {
        TasksView()
    }
}
