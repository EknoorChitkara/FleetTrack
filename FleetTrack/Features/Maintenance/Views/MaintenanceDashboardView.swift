//
//  MaintenanceDashboardView.swift
//  FleetTrack
//
//  Created by FleetTrack Team on 2026-01-09.
//

import SwiftUI

struct MaintenanceDashboardView: View {
    let user: User
    @ObservedObject var viewModel: MaintenanceDashboardViewModel
    @Binding var selectedTab: Int
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacing.lg) {
                    // Header
                    headerView
                    
                    // Today's Tasks Card
                    TodaysTasksCard(
                        pendingCount: viewModel.pendingTasksCount,
                        inProgressCount: viewModel.inProgressTasksCount
                    )
                    .padding(.horizontal, AppTheme.spacing.md)
                    
                    // Statistics Row
                    HStack(spacing: AppTheme.spacing.md) {
                        StatisticCard(
                            icon: "chart.bar.fill",
                            value: "\(viewModel.maintenanceSummary.completedTasksThisMonth)",
                            label: "Completed This Month",
                            iconBackgroundColor: Color.purple.opacity(0.15),
                            iconColor: Color.purple
                        )
                        
                        StatisticCard(
                            icon: "timer",
                            value: String(format: "%.1fh", viewModel.maintenanceSummary.averageCompletionTimeHours),
                            label: "Avg Completion Time",
                            iconBackgroundColor: Color.orange.opacity(0.15),
                            iconColor: Color.orange
                        )
                    }
                    .padding(.horizontal, AppTheme.spacing.md)
                    
                    // Priority Tasks Section
                    priorityTasksSection
                    
                    // Task History Section
                    taskHistorySection
                    
                    // Quick Actions (moved to bottom)
                    quickActionsSection
                        .padding(.horizontal, AppTheme.spacing.md)
                        .padding(.bottom, 80) // Extra padding to clear tab bar
                }
                .padding(.vertical, AppTheme.spacing.md)
            }
            .refreshable {
                await viewModel.refreshData()
            }
        }

        .onAppear {
             if !viewModel.isLoading {
                 InAppVoiceManager.shared.speak(voiceSummary())
             }
        }
        .onChange(of: viewModel.isLoading) { loading in
            if !loading {
                // Speak when loading finishes
                 InAppVoiceManager.shared.speak(voiceSummary())
            }
        }
        .sheet(isPresented: $showingTaskHistory) {
            TaskHistoryView()
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(false)
                .onDisappear {
                    // Ensure we stay on Dashboard tab when sheet dismisses
                    if selectedTab != 0 {
                        withAnimation(.none) {
                            selectedTab = 0
                        }
                    }
                }
        }
        .sheet(isPresented: $showProfile) {
            MaintenanceProfileView(user: user)
        }
        .sheet(isPresented: $showingInspections) {
            MaintenanceInspectionView()
        }
        }
    }
    
    @State private var showingTaskHistory = false
    @State private var showingInspections = false
    @State private var showProfile = false
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Maintenance")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Management Dashboard")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Profile Icon - simple green circle with person
            Button(action: {
                showProfile = true
            }) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentPrimary)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            .accessibilityLabel("Maintenance Profile")
            .accessibilityHint("Double tap to view profile details")
            .accessibilityIdentifier("maintenance_profile_button")
        }
        .padding(.horizontal, AppTheme.spacing.md)
        .accessibilityIdentifier("maintenance_dashboard_header")
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            Button(action: {
                showingInspections = true
            }) {
                HStack {
                    Image(systemName: "checklist")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Daily Inspections")
                        .fontWeight(.medium)
                }
                .foregroundColor(AppTheme.textInverse)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(AppTheme.accentPrimary)
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Perform Daily Inspections")
            .accessibilityHint("Double tap to start inspection workflow")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("maintenance_action_inspections")
        }
    }
    
    // MARK: - Priority Tasks Section
    
    private var priorityTasksSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            // Section Header
            HStack {
                Text("Recent Tasks")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Button(action: {
                    // Navigate to Tasks tab
                    selectedTab = 1
                }) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.accentPrimary)
                }
                .accessibilityLabel("View All Priority Tasks")
                .accessibilityIdentifier("maintenance_view_all_tasks")
            }
            .padding(.horizontal, AppTheme.spacing.md)
            .accessibilityIdentifier("maintenance_recent_tasks_header")
            
            // Task List
            VStack(spacing: AppTheme.spacing.sm) {
                ForEach(viewModel.highPriorityMaintenanceTasks) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        PriorityTaskRow(task: task)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, AppTheme.spacing.md)
        }
    }
    
    // MARK: - Task History Section
    
    private var taskHistorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            // Section Header
            HStack {
                Text("Recent History")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Button(action: {
                    showingTaskHistory = true
                }) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.accentPrimary)
                }
                .accessibilityLabel("View Task History")
                .accessibilityIdentifier("maintenance_view_all_history")
            }
            .padding(.horizontal, AppTheme.spacing.md)
            .accessibilityIdentifier("maintenance_recent_history_header")
            
            // History List (show first 3)
            VStack(spacing: AppTheme.spacing.sm) {
                ForEach(Array(viewModel.completedTasks.prefix(3))) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        CompletedTaskRow(task: task)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, AppTheme.spacing.md)
        }
    }
}

// MARK: - InAppVoiceReadable
extension MaintenanceDashboardView: InAppVoiceReadable {
    func voiceSummary() -> String {
        var summary = "Maintenance Dashboard. "
        
        // Task Overview
        summary += "Overview. You have \(viewModel.pendingTasksCount) pending and \(viewModel.inProgressTasksCount) in-progress tasks. "
        
        // Stats
        summary += "Statistics. \(viewModel.maintenanceSummary.completedTasksThisMonth) tasks completed this month. Average completion time is \(String(format: "%.1f", viewModel.maintenanceSummary.averageCompletionTimeHours)) hours. "
        
        // Priority Tasks
        if !viewModel.highPriorityMaintenanceTasks.isEmpty {
            summary += "Recent Tasks: "
            if let first = viewModel.highPriorityMaintenanceTasks.first {
                let taskTitle = first.description ?? "\(first.component.rawValue) check for \(first.vehicleRegistrationNumber)"
                summary += "Top priority: \(taskTitle). "
            }
        }
        
        // Task History (Added Detailed Enumeration based on user request)
        let completed = viewModel.completedTasks.prefix(3)
        if !completed.isEmpty {
            summary += "Recent history: "
            for task in completed {
                let description = task.description ?? "\(task.component.rawValue) task"
                summary += "Completed \(description) for \(task.vehicleRegistrationNumber). "
            }
        }
        
        summary += "Quick Actions: Daily Inspections. "
        
        return summary
    }
}

#Preview {
    MaintenanceDashboardView(
        user: .testAdmin(),
        viewModel: MaintenanceDashboardViewModel(user: .testAdmin()),
        selectedTab: .constant(0)
    )
}
