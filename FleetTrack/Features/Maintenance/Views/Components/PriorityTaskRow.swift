//
//  PriorityTaskRow.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import SwiftUI

struct PriorityTaskRow: View {
    let task: MaintenanceTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
            // Header: Task ID and Priority Badge
            HStack {
                Text(task.id.uuidString.prefix(12).uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                PriorityBadge(priority: task.priority)
            }
            
            // Vehicle Number
            Text(task.vehicleRegistrationNumber)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            
            // Task Description (Component name)
            Text(task.component.rawValue)
                .font(.subheadline)
                .foregroundColor(AppTheme.textPrimary)
            
            // Due Date
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(AppTheme.iconDefault)
                
                Text("Due: \(formattedDate(task.dueDate))")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
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
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd"
            return formatter.string(from: date)
        }
    }
}

struct PriorityBadge: View {
    let priority: MaintenancePriority
    
    var badgeColor: Color {
        switch priority {
        case .high:
            return AppTheme.statusError
        case .medium:
            return AppTheme.statusWarning
        case .low:
            return AppTheme.statusIdle
        }
    }
    
    var backgroundColor: Color {
        switch priority {
        case .high:
            return AppTheme.statusErrorBackground
        case .medium:
            return AppTheme.statusWarningBackground
        case .low:
            return AppTheme.statusIdleBackground
        }
    }
    
    var body: some View {
        Text(priority.rawValue.lowercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(badgeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(6)
    }
}

#Preview {
    VStack(spacing: 12) {
        PriorityTaskRow(
            task: MaintenanceTask(
                vehicleRegistrationNumber: "TRK-001",
                priority: MaintenancePriority.high,
                component: MaintenanceComponent.oilChange,
                dueDate: Date()
            )
        )
        
        PriorityTaskRow(
            task: MaintenanceTask(
                vehicleRegistrationNumber: "VAN-002",
                priority: MaintenancePriority.medium,
                component: MaintenanceComponent.tireReplacement,
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            )
        )
    }
    .padding()
    .background(AppTheme.backgroundPrimary)
}
