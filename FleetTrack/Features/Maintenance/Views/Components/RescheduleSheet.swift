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
    
    @State private var newDate: Date = Date()
    @State private var reason: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.spacing.lg) {
                    Text("Request to reschedule this task to a new date")
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
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .padding(12)
                        .background(AppTheme.backgroundSecondary)
                        .cornerRadius(AppTheme.cornerRadius.small)
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                        Text("Reason for Rescheduling *")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextEditor(text: $reason)
                            .frame(height: 100)
                            .padding(8)
                            .background(AppTheme.backgroundSecondary)
                            .cornerRadius(AppTheme.cornerRadius.small)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    // Info box
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppTheme.accentPrimary)
                        
                        Text("This request will be sent to the Fleet Manager for approval")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(12)
                    .background(AppTheme.backgroundElevated)
                    .cornerRadius(AppTheme.cornerRadius.small)
                    
                    Spacer()
                    
                    Button(action: {
                        if !reason.isEmpty {
                            Task {
                                await viewModel.requestReschedule(newDate: newDate, reason: reason)
                                dismiss()
                            }
                        }
                    }) {
                        Text("Submit Reschedule Request")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                !reason.isEmpty
                                    ? AppTheme.accentPrimary
                                    : AppTheme.textTertiary
                            )
                            .cornerRadius(AppTheme.cornerRadius.medium)
                    }
                    .disabled(reason.isEmpty)
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
                        Text("Cancellation Reason *")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextEditor(text: $reason)
                            .frame(height: 150)
                            .padding(8)
                            .background(AppTheme.backgroundSecondary)
                            .cornerRadius(AppTheme.cornerRadius.small)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    // Warning box
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.statusWarning)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("This request requires approval")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text("Fleet Manager will review your cancellation request")
                                .font(.caption2)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding(12)
                    .background(AppTheme.statusWarningBackground)
                    .cornerRadius(AppTheme.cornerRadius.small)
                    
                    Spacer()
                    
                    Button(action: {
                        if !reason.isEmpty {
                            showConfirmation = true
                        }
                    }) {
                        Text("Submit Cancellation Request")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                !reason.isEmpty
                                    ? AppTheme.statusError
                                    : AppTheme.textTertiary
                            )
                            .cornerRadius(AppTheme.cornerRadius.medium)
                    }
                    .disabled(reason.isEmpty)
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
                Button("Cancel Request", role: .cancel) { }
                Button("Submit", role: .destructive) {
                    Task {
                        await viewModel.requestCancellation(reason: reason)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to submit a cancellation request for this task?")
            }
        }
    }
}
