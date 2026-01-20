//
//  TaskHistoryView.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//


import SwiftUI

struct TaskHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var completedTasks: [MaintenanceTask] = []
    @State private var isLoading = false
    
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
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.accentPrimary))
                    Spacer()
                } else if completedTasks.isEmpty {
                    Spacer()
                    Text("No completed tasks")
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                } else {
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
        }
        .navigationBarHidden(true)
        .task {
            await loadCompletedTasks()
        }
    }
    
    private func loadCompletedTasks() async {
        isLoading = true
        do {
            let allTasks = try await MaintenanceService.shared.fetchMaintenanceTasks()
            completedTasks = allTasks
                .filter { $0.status == "Completed" }
                .sorted { ($0.completedDate ?? Date.distantPast) > ($1.completedDate ?? Date.distantPast) }
        } catch {
            print("❌ Error loading completed tasks: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    TaskHistoryView()
}
