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
        .sheet(isPresented: $showingTaskHistory) {
            TaskHistoryView()
        }
        .sheet(isPresented: $showProfile) {
            MaintenanceProfileView(user: user)
        }
        .sheet(isPresented: $showingInspections) {
            MaintenanceInspectionView()
        }
    }
    
    @State private var showingTaskHistory = false
    @State private var showingInspections = false
    @State private var showProfile = false
    
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
            .accessibilityLabel("Profile")
        }
        .padding(.horizontal, AppTheme.spacing.md)
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
            .accessibilityLabel("Perform Daily Inspections")
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
        user: .testAdmin(),
        viewModel: MaintenanceDashboardViewModel(user: .testAdmin()),
        selectedTab: .constant(0)
    )
}
