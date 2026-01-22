//
//  RescheduleSheet.swift
//  FleetTrack
//
//  Created for Maintenance Module - Task Management
//

import SwiftUI

struct RescheduleSheet: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var newDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var reason: String = ""
    
    // Minimum date is tomorrow
    private var minimumDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
    
    private var isReasonValid: Bool {
        reason.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
    }
    
    private var characterCount: Int {
        reason.trimmingCharacters(in: .whitespacesAndNewlines).count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.spacing.lg) {
                    Text("Select a new due date for this task")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                        Text("New Due Date *")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        DatePicker(
                            "Select Date",
                            selection: $newDate,
                            in: minimumDate...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .padding(12)
                        .background(AppTheme.backgroundSecondary)
                        .cornerRadius(AppTheme.cornerRadius.small)
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                        HStack {
                            Text("Reason for Rescheduling *")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Spacer()
                            
                            Text("\(characterCount)/10")
                                .font(.caption2)
                                .foregroundColor(isReasonValid ? AppTheme.statusActiveText : AppTheme.statusError)
                        }
                        
                        TextEditor(text: $reason)
                            .frame(height: 100)
                            .padding(8)
                            .background(AppTheme.backgroundSecondary)
                            .cornerRadius(AppTheme.cornerRadius.small)
                            .foregroundColor(AppTheme.textPrimary)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius.small)
                                    .stroke(isReasonValid ? Color.clear : AppTheme.statusError, lineWidth: 1)
                            )
                        
                        if !isReasonValid && !reason.isEmpty {
                            Text("Minimum 10 characters required")
                                .font(.caption2)
                                .foregroundColor(AppTheme.statusError)
                        }
                    }
                    
                    // Info box
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppTheme.accentPrimary)
                        
                        Text("Task will be rescheduled immediately. An alert will be sent to the fleet manager.")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(12)
                    .background(AppTheme.backgroundElevated)
                    .cornerRadius(AppTheme.cornerRadius.small)
                    
                    Spacer()
                    
                    Button(action: {
                        if isReasonValid {
                            Task {
                                await viewModel.rescheduleTask(newDate: newDate, reason: reason)
                                dismiss()
                            }
                        }
                    }) {
                        Text("Reschedule Task")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                isReasonValid
                                    ? AppTheme.accentPrimary
                                    : AppTheme.textTertiary
                            )
                            .cornerRadius(AppTheme.cornerRadius.medium)
                    }
                    .disabled(!isReasonValid)
                }
                .padding(AppTheme.spacing.md)
            }
            .navigationTitle("Reschedule Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentPrimary)
                }
            }
        }
    }
}

struct CancelTaskSheet: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var reason: String = ""
    @State private var showConfirmation: Bool = false
    
    private var isReasonValid: Bool {
        reason.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
    }
    
    private var characterCount: Int {
        reason.trimmingCharacters(in: .whitespacesAndNewlines).count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.spacing.lg) {
                    Text("Explain why this task needs to be cancelled")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                        HStack {
                            Text("Cancellation Reason *")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Spacer()
                            
                            Text("\(characterCount)/10")
                                .font(.caption2)
                                .foregroundColor(isReasonValid ? AppTheme.statusActiveText : AppTheme.statusError)
                        }
                        
                        TextEditor(text: $reason)
                            .frame(height: 150)
                            .padding(8)
                            .background(AppTheme.backgroundSecondary)
                            .cornerRadius(AppTheme.cornerRadius.small)
                            .foregroundColor(AppTheme.textPrimary)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius.small)
                                    .stroke(isReasonValid ? Color.clear : AppTheme.statusError, lineWidth: 1)
                            )
                        
                        if !isReasonValid && !reason.isEmpty {
                            Text("Minimum 10 characters required")
                                .font(.caption2)
                                .foregroundColor(AppTheme.statusError)
                        }
                    }
                    
                    // Warning box
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.statusWarning)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Task will be cancelled immediately")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text("An alert will be sent to the fleet manager")
                                .font(.caption2)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding(12)
                    .background(AppTheme.statusWarningBackground)
                    .cornerRadius(AppTheme.cornerRadius.small)
                    
                    Spacer()
                    
                    Button(action: {
                        if isReasonValid {
                            showConfirmation = true
                        }
                    }) {
                        Text("Cancel Task")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                isReasonValid
                                    ? AppTheme.statusError
                                    : AppTheme.textTertiary
                            )
                            .cornerRadius(AppTheme.cornerRadius.medium)
                    }
                    .disabled(!isReasonValid)
                }
                .padding(AppTheme.spacing.md)
            }
            .navigationTitle("Cancel Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentPrimary)
                }
            }
            .alert("Confirm Cancellation", isPresented: $showConfirmation) {
                Button("Don't Cancel", role: .cancel) { }
                Button("Cancel Task", role: .destructive) {
                    Task {
                        await viewModel.cancelTask(reason: reason)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to cancel this task? This action will lock the task and notify the fleet manager.")
            }
        }
    }
}
