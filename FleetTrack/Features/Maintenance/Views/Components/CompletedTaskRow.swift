//
//  CompletedTaskRow.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import SwiftUI

struct CompletedTaskRow: View {
    let task: MaintenanceTask
    
    var body: some View {
        HStack(spacing: AppTheme.spacing.md) {
            // Status icon with circular background
            ZStack {
                Circle()
                    .fill(AppTheme.statusActiveBackground.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.statusActiveText)
            }
            
            // Task details
            VStack(alignment: .leading, spacing: 4) {
                Text(task.id.uuidString.prefix(8).uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(task.vehicleRegistrationNumber)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                
                Text(task.component.rawValue)
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
            
            Spacer()
            
            // Completed date
            VStack(alignment: .trailing, spacing: 4) {
                Text("Completed")
                    .font(.caption2)
                    .foregroundColor(AppTheme.statusActiveText)
                
                Text(formattedDate(task.dueDate))
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Completed Task: \(task.component.rawValue) for vehicle \(task.vehicleRegistrationNumber). Finished on \(formattedDate(task.dueDate)).")
        .accessibilityIdentifier("maintenance_completed_task_\(task.id.uuidString.prefix(8))")
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 12) {
        CompletedTaskRow(
            task: MaintenanceTask(
                vehicleRegistrationNumber: "TRK-001",
                priority: MaintenancePriority.medium,
                component: MaintenanceComponent.oilChange,
                dueDate: Date()
            )
        )
    }
    .padding()
    .background(AppTheme.backgroundPrimary)
}
