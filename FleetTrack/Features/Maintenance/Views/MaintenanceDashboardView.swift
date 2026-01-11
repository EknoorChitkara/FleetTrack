//
//  MaintenanceDashboardView.swift
//  FleetTrack
//
//  Created by FleetTrack Team on 2026-01-09.
//

import SwiftUI

struct MaintenanceDashboardView: View {
    @ObservedObject var viewModel: MaintenanceDashboardViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
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
                            icon: "checkmark",
                            value: "\(viewModel.maintenanceSummary.completedTasksThisMonth)",
                            label: "Completed This Month",
                            iconBackgroundColor: AppTheme.statusActiveBackground
                        )
                        
                        StatisticCard(
                            icon: "clock",
                            value: String(format: "%.1fh", viewModel.maintenanceSummary.averageCompletionTimeHours),
                            label: "Avg Completion Time",
                            iconBackgroundColor: AppTheme.backgroundElevated
                        )
                    }
                    .padding(.horizontal, AppTheme.spacing.md)
                    
                    // Priority Tasks Section
                    priorityTasksSection
                    
                    // Task History Section
                    taskHistorySection
                }
                .padding(.vertical, AppTheme.spacing.md)
            }
        }
        .sheet(isPresented: $showingTaskHistory) {
            TaskHistoryView(completedTasks: viewModel.completedTasks)
        }
    }
    
    @State private var showingTaskHistory = false
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Maintenance Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Welcome back, \(viewModel.currentUser.name)!")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Profile Icon - simple green circle with person
            Button(action: {
                // Handle profile navigation
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
        }
        .padding(.horizontal, AppTheme.spacing.md)
    }
    
    // MARK: - Priority Tasks Section
    
    private var priorityTasksSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            // Section Header
            HStack {
                Text("Priority Tasks")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Button(action: {
                    // Navigate to Tasks tab
                    selectedTab = 1
                }) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.accentPrimary)
                }
            }
            .padding(.horizontal, AppTheme.spacing.md)
            
            // Task List
            VStack(spacing: AppTheme.spacing.sm) {
                ForEach(viewModel.highPriorityMaintenanceTasks) { task in
                    PriorityTaskRow(task: task)
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
                
                Spacer()
                
                Button(action: {
                    showingTaskHistory = true
                }) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.accentPrimary)
                }
            }
            .padding(.horizontal, AppTheme.spacing.md)
            
            // History List (show first 3)
            VStack(spacing: AppTheme.spacing.sm) {
                ForEach(Array(viewModel.completedTasks.prefix(3))) { task in
                    CompletedTaskRow(task: task)
                }
            }
            .padding(.horizontal, AppTheme.spacing.md)
        }
    }
}

#Preview {
    MaintenanceDashboardView(
        viewModel: MaintenanceDashboardViewModel(),
        selectedTab: .constant(0)
    )
}
