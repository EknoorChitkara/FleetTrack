//
//  PasswordResetView.swift
//  FleetTrack
//
//  Created by Firebase Integration
//

import SwiftUI

/// In-app password reset view (accessed via deep link)
struct PasswordResetView: View {
    
    @StateObject private var viewModel = PasswordResetViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let oobCode: String
    let onSuccess: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView("Verifying reset link...")
                        .padding()
                } else if !viewModel.email.isEmpty {
                    // Show reset form
                    resetForm
                } else if viewModel.showError {
                    // Show error state
                    errorView
                }
            }
            .padding()
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.initialize(oobCode: oobCode)
        }
        .alert("Success", isPresented: $viewModel.resetSuccessful) {
            Button("Go to Login") {
                onSuccess()
            }
        } message: {
            Text("Your password has been reset successfully. You can now log in with your new password.")
        }
    }
    
    private var resetForm: some View {
        VStack(spacing: 20) {
            // Email display
            VStack(alignment: .leading, spacing: 8) {
                Text("Resetting password for:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(viewModel.email)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            // New Password
            VStack(alignment: .leading, spacing: 8) {
                SecureField("New Password", text: $viewModel.newPassword)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)
                    .accessibilityLabel("New Password")
                    .accessibilityIdentifier("pwdreset_new_password_field")
                    .onChange(of: viewModel.newPassword) { _ in
                        viewModel.validateNewPassword()
                    }
                
                if let error = viewModel.newPasswordError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                // Password strength indicator
                PasswordStrengthIndicator(strength: viewModel.passwordStrength)
            }
            
            // Confirm Password
            VStack(alignment: .leading, spacing: 8) {
                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)
                    .accessibilityLabel("Confirm New Password")
                    .accessibilityIdentifier("pwdreset_confirm_password_field")
                    .onChange(of: viewModel.confirmPassword) { _ in
                        viewModel.validateConfirmPassword()
                    }
                
                if let error = viewModel.confirmPasswordError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Reset Button
            Button {
                Task {
                    await viewModel.resetPassword()
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text("Reset Password")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .accessibilityLabel("Reset Password Button")
            .accessibilityIdentifier("pwdreset_button")
            .disabled(viewModel.isLoading)
            
            Spacer()
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text(viewModel.errorMessage ?? "An error occurred")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Password Strength Indicator

struct PasswordStrengthIndicator: View {
    let strength: ValidationHelpers.PasswordStrength
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Rectangle()
                        .fill(index < strength.rawValue ? strengthColor : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            
            Text(strengthText)
                .font(.caption)
                .foregroundColor(strengthColor)
        }
        .accessibilityLabel("Password strength: \(strengthText)")
        .accessibilityIdentifier("pwdreset_strength_indicator")
    }
    
    private var strengthColor: Color {
        switch strength {
        case .veryWeak, .weak:
            return .red
        case .medium:
            return .orange
        case .strong:
            return .green
        case .veryStrong:
            return .blue
        }
    }
    
    private var strengthText: String {
        switch strength {
        case .veryWeak:
            return "Very Weak"
        case .weak:
            return "Weak"
        case .medium:
            return "Medium"
        case .strong:
            return "Strong"
        case .veryStrong:
            return "Very Strong"
        }
    }
}
