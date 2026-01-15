//
//  TaskFilterSheet.swift
//  FleetTrack
//
//  Created for Maintenance Module - Task Management
//

import SwiftUI

struct TaskFilterSheet: View {
    @ObservedObject var viewModel: TasksViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spacing.lg) {
                        // Date Filter Section
                        dateFilterSection
                        
                        Divider()
                            .background(AppTheme.dividerPrimary)
                        
                        // Priority Filter Section
                        priorityFilterSection
                        
                        Divider()
                            .background(AppTheme.dividerPrimary)
                        
                        // Status Filter Section
                        statusFilterSection
                    }
                    .padding(AppTheme.spacing.md)
                }
            }
            .navigationTitle("Filter Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        viewModel.clearAllFilters()
                    }
                    .foregroundColor(AppTheme.accentPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentPrimary)
                }
            }
        }
    }
    
    // MARK: - Date Filter Section
    
    private var dateFilterSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            Text("Date")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            VStack(spacing: AppTheme.spacing.sm) {
                ForEach(DateFilterOption.allCases, id: \.self) { option in
                    FilterOptionButton(
                        title: option.rawValue,
                        isSelected: viewModel.dateFilter == option
                    ) {
                        viewModel.updateDateFilter(option)
                    }
                }
            }
        }
    }
    
    // MARK: - Priority Filter Section
    
    private var priorityFilterSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            Text("Priority")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            HStack(spacing: AppTheme.spacing.sm) {
                ForEach(MaintenancePriority.allCases, id: \.self) { priority in
                    PriorityFilterChip(
                        priority: priority,
                        isSelected: viewModel.selectedPriorities.contains(priority)
                    ) {
                        viewModel.togglePriority(priority)
                    }
                }
            }
        }
    }
    
    // MARK: - Status Filter Section
    
    private var statusFilterSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            Text("Status")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            let statuses = ["Pending", "In Progress", "Paused", "Completed", "Failed"]
            
            VStack(spacing: AppTheme.spacing.sm) {
                ForEach(statuses, id: \.self) { status in
                    FilterOptionButton(
                        title: status,
                        isSelected: viewModel.selectedStatuses.contains(status)
                    ) {
                        viewModel.toggleStatus(status)
                    }
                }
            }
        }
    }
}

// MARK: - Filter Option Button

struct FilterOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.accentPrimary)
                }
            }
            .padding(AppTheme.spacing.md)
            .background(isSelected ? AppTheme.backgroundElevated : AppTheme.backgroundSecondary)
            .cornerRadius(AppTheme.cornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius.medium)
                    .stroke(isSelected ? AppTheme.accentPrimary : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Priority Filter Chip

struct PriorityFilterChip: View {
    let priority: MaintenancePriority
    let isSelected: Bool
    let action: () -> Void
    
    var priorityColor: Color {
        switch priority {
        case .high:
            return AppTheme.statusError
        case .medium:
            return AppTheme.statusWarning
        case .low:
            return AppTheme.statusIdle
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(priority.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? priorityColor.opacity(0.2) : AppTheme.backgroundSecondary)
                .cornerRadius(AppTheme.cornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius.medium)
                        .stroke(isSelected ? priorityColor : Color.clear, lineWidth: 2)
                )
        }
    }
}

#Preview {
    TaskFilterSheet(viewModel: TasksViewModel())
}
