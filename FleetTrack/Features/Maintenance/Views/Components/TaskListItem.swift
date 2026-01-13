//
//  TaskListItem.swift
//  FleetTrack
//
//  Created for Maintenance Module - Task Management
//

import SwiftUI

struct TaskListItem: View {
    let task: MaintenanceTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
            // Header Row: Vehicle Number and Task Type
            HStack {
                // Vehicle Number
                HStack(spacing: 4) {
                    Image(systemName: "car.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.iconDefault)
                    
                    Text(task.vehicleRegistrationNumber)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                Spacer()
                
                // Task Type Badge
                HStack(spacing: 4) {
                    Image(systemName: task.taskType.icon)
                        .font(.caption2)
                    
                    Text(task.taskType.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(task.taskType == .emergency ? AppTheme.statusError : AppTheme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    task.taskType == .emergency
                        ? AppTheme.statusErrorBackground
                        : AppTheme.backgroundElevated
                )
                .cornerRadius(6)
            }
            
            // Component/Description
            Text(task.component.rawValue)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.textPrimary)
            
            if let description = task.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            
            // Bottom Row: Priority, Due Date, Status
            HStack(spacing: AppTheme.spacing.sm) {
                // Priority Badge
                PriorityBadge(priority: task.priority)
                
                // Due Date
                HStack(spacing: 4) {
                    Image(systemName: task.isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                        .font(.caption2)
                        .foregroundColor(task.isOverdue ? AppTheme.statusError : AppTheme.iconDefault)
                    
                    Text(formattedDate(task.dueDate))
                        .font(.caption)
                        .foregroundColor(task.isOverdue ? AppTheme.statusError : AppTheme.textTertiary)
                }
                
                Spacer()
                
                // Status Badge
                StatusBadge(status: task.status)
            }
        }
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if date < Date() {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd"
            return formatter.string(from: date) + " (Overdue)"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: String
    
    var statusColor: Color {
        switch status {
        case "Pending":
            return AppTheme.statusWarning
        case "In Progress":
            return AppTheme.accentPrimary
        case "Paused":
            return AppTheme.statusIdle
        case "Completed":
            return AppTheme.statusActiveText
        case "Failed":
            return AppTheme.statusError
        default:
            return AppTheme.textSecondary
        }
    }
    
    var backgroundColor: Color {
        switch status {
        case "Pending":
            return AppTheme.statusWarningBackground
        case "In Progress":
            return AppTheme.statusActiveBackground
        case "Paused":
            return AppTheme.statusIdleBackground
        case "Completed":
            return AppTheme.statusActiveBackground
        case "Failed":
            return AppTheme.statusErrorBackground
        default:
            return AppTheme.backgroundElevated
        }
    }
    
    var body: some View {
        Text(status)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(6)
    }
}

#Preview {
    VStack(spacing: 12) {
        TaskListItem(
            task: MaintenanceTask(
                vehicleRegistrationNumber: "MH-01-AB-1234",
                priority: .high,
                component: .brakes,
                status: "Pending",
                dueDate: Date(),
                taskType: .emergency,
                description: "Brake pads need immediate replacement"
            )
        )
        
        TaskListItem(
            task: MaintenanceTask(
                vehicleRegistrationNumber: "DL-01-XY-5678",
                priority: .medium,
                component: .engine,
                status: "In Progress",
                dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                taskType: .scheduled,
                description: "Regular engine maintenance check"
            )
        )
    }
    .padding()
    .background(AppTheme.backgroundPrimary)
}
