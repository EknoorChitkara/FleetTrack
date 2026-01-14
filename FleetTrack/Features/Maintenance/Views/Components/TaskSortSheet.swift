//
//  TaskSortSheet.swift
//  FleetTrack
//
//  Created for Maintenance Module - Task Management
//

import SwiftUI

struct TaskSortSheet: View {
    @ObservedObject var viewModel: TasksViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
                    Text("Sort By")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, AppTheme.spacing.md)
                        .padding(.top, AppTheme.spacing.md)
                    
                    VStack(spacing: AppTheme.spacing.sm) {
                        ForEach(TaskSortOption.allCases, id: \.self) { option in
                            Button(action: {
                                viewModel.updateSortOption(option)
                                dismiss()
                            }) {
                                HStack {
                                    Text(option.rawValue)
                                        .font(.subheadline)
                                        .foregroundColor(viewModel.sortOption == option ? AppTheme.textPrimary : AppTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    if viewModel.sortOption == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppTheme.accentPrimary)
                                    }
                                }
                                .padding(AppTheme.spacing.md)
                                .background(viewModel.sortOption == option ? AppTheme.backgroundElevated : AppTheme.backgroundSecondary)
                                .cornerRadius(AppTheme.cornerRadius.medium)
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing.md)
                    
                    Spacer()
                }
            }
            .navigationTitle("Sort Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentPrimary)
                }
            }
        }
    }
}

#Preview {
    TaskSortSheet(viewModel: TasksViewModel())
}
