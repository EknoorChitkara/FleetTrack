//
//  TaskHistoryView.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//


import SwiftUI

struct TaskHistoryView: View {
    @Environment(\.dismiss) var dismiss
    let completedTasks: [MaintenanceTask]
    
    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    Text("Task History")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                }
                .padding()
                .background(AppTheme.backgroundPrimary)
                
                // Task list
                ScrollView {
                    VStack(spacing: AppTheme.spacing.sm) {
                        ForEach(completedTasks) { task in
                            CompletedTaskRow(task: task)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    TaskHistoryView(
        completedTasks: [
            MaintenanceTask(
                vehicleRegistrationNumber: "TRK-001",
                priority: MaintenancePriority.medium,
                component: MaintenanceComponent.oilChange,
                dueDate: Date()
            )
        ]
    )
}
