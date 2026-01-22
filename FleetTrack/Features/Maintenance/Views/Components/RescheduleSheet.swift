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
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var minimumDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
    
    private var isValid: Bool {
        !reason.trimmingCharacters(in: .whitespaces).isEmpty && 
        reason.trimmingCharacters(in: .whitespaces).count >= 10
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.spacing.lg) {
                    Text("Reschedule this task to a new date")
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
                        Text("Reason for Rescheduling * (minimum 10 characters)")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextEditor(text: $reason)
                            .frame(height: 100)
                            .padding(8)
                            .background(AppTheme.backgroundSecondary)
                            .cornerRadius(AppTheme.cornerRadius.small)
                            .foregroundColor(AppTheme.textPrimary)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius.small)
                                    .stroke(
                                        reason.count > 0 && reason.count < 10 ? Color.red : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                        
                        if reason.count > 0 && reason.count < 10 {
                            Text("\(reason.count)/10 characters")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Info box
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppTheme.accentPrimary)
                        
                        Text("The task will be rescheduled immediately and an alert will be sent to the Fleet Manager")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(12)
                    .background(AppTheme.backgroundElevated)
                    .cornerRadius(AppTheme.cornerRadius.small)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await viewModel.rescheduleTask(newDate: newDate, reason: reason)
                            dismiss()
                        }
                    }) {
                        Text("Reschedule Task")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                isValid
                                    ? AppTheme.accentPrimary
                                    : AppTheme.textTertiary
                            )
                            .cornerRadius(AppTheme.cornerRadius.medium)
                    }
                    .disabled(!isValid)
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
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}


struct CancelTaskSheet: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var reason: String = ""
    @State private var showConfirmation: Bool = false
    
    private var isValid: Bool {
        !reason.trimmingCharacters(in: .whitespaces).isEmpty && 
        reason.trimmingCharacters(in: .whitespaces).count >= 10
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.spacing.lg) {
                    Text("Cancel this maintenance task")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                        Text("Cancellation Reason * (minimum 10 characters)")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextEditor(text: $reason)
                            .frame(height: 150)
                            .padding(8)
                            .background(AppTheme.backgroundSecondary)
                            .cornerRadius(AppTheme.cornerRadius.small)
                            .foregroundColor(AppTheme.textPrimary)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius.small)
                                    .stroke(
                                        reason.count > 0 && reason.count < 10 ? Color.red : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                        
                        if reason.count > 0 && reason.count < 10 {
                            Text("\(reason.count)/10 characters")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Warning box
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.statusWarning)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("This will cancel the task immediately")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text("The task will be moved to cancelled section and an alert will be sent to Fleet Manager")
                                .font(.caption2)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding(12)
                    .background(AppTheme.statusWarningBackground)
                    .cornerRadius(AppTheme.cornerRadius.small)
                    
                    Spacer()
                    
                    Button(action: {
                        if isValid {
                            showConfirmation = true
                        }
                    }) {
                        Text("Cancel Task")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                isValid
                                    ? AppTheme.statusError
                                    : AppTheme.textTertiary
                            )
                            .cornerRadius(AppTheme.cornerRadius.medium)
                    }
                    .disabled(!isValid)
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
                Text("Are you sure you want to cancel this task? This action cannot be undone.")
            }
        }
    }
}
