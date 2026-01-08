//
//  PasswordRecoveryViewModel.swift
//  authFMS
//
//  Created by Authentication System
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for password recovery flow
@MainActor
class PasswordRecoveryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Step 1: Request reset
    @Published var email = ""
    @Published var emailError: String?
    
    // Step 2: Reset password
    @Published var resetToken = ""
    @Published var newPassword = ""
    @Published var confirmNewPassword = ""
    @Published var newPasswordError: String?
    @Published var confirmNewPasswordError: String?
    
    // Password strength
    @Published var passwordStrength: ValidationHelpers.PasswordStrength = .veryWeak
    @Published var passwordRequirements: [String: Bool] = [:]
    
    // UI state
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Flow state
    @Published var resetEmailSent = false
    @Published var resetSuccessful = false
    
    // MARK: - Services
    
    private let authService = MockAuthService.shared
    
    // MARK: - Validation
    
    /// Validate email
    func validateEmail() {
        emailError = ValidationHelpers.emailValidationMessage(email)
    }
    
    /// Validate new password
    func validateNewPassword() {
        newPasswordError = ValidationHelpers.passwordValidationMessage(newPassword)
        passwordStrength = ValidationHelpers.passwordStrength(newPassword)
        passwordRequirements = ValidationHelpers.passwordRequirements(newPassword)
    }
    
    /// Validate confirm password
    func validateConfirmNewPassword() {
        if confirmNewPassword.isEmpty {
            confirmNewPasswordError = "Please confirm your password"
        } else if newPassword != confirmNewPassword {
            confirmNewPasswordError = "Passwords do not match"
        } else {
            confirmNewPasswordError = nil
        }
    }
    
    // MARK: - Password Reset Flow
    
    /// Step 1: Request password reset
    func requestPasswordReset() async {
        validateEmail()
        
        guard emailError == nil && !email.isEmpty else {
            errorMessage = "Please enter a valid email address"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let token = try await authService.requestPasswordReset(email: email)
            
            // In a real app, the token would be sent via email
            // For demo purposes, we'll store it
            resetToken = token
            resetEmailSent = true
            
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
        }
    }
    
    /// Step 2: Reset password with token
    func resetPassword() async {
        validateNewPassword()
        validateConfirmNewPassword()
        
        guard newPasswordError == nil &&
              confirmNewPasswordError == nil &&
              !newPassword.isEmpty &&
              !confirmNewPassword.isEmpty else {
            errorMessage = "Please fix the errors above"
            showError = true
            return
        }
        
        guard !resetToken.isEmpty else {
            errorMessage = "Invalid reset token"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.resetPassword(token: resetToken, newPassword: newPassword)
            
            resetSuccessful = true
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
        }
    }
    
    /// Simulate clicking reset link (for demo purposes)
    func simulateResetLink(token: String) {
        resetToken = token
        resetEmailSent = true
    }
    
    // MARK: - State Management
    
    /// Reset to initial state
    func resetToInitial() {
        email = ""
        emailError = nil
        resetToken = ""
        newPassword = ""
        confirmNewPassword = ""
        newPasswordError = nil
        confirmNewPasswordError = nil
        passwordStrength = .veryWeak
        passwordRequirements = [:]
        isLoading = false
        errorMessage = nil
        showError = false
        resetEmailSent = false
        resetSuccessful = false
    }
    
    /// Reset to step 1 (request reset)
    func backToRequestReset() {
        resetToken = ""
        newPassword = ""
        confirmNewPassword = ""
        newPasswordError = nil
        confirmNewPasswordError = nil
        passwordStrength = .veryWeak
        passwordRequirements = [:]
        resetEmailSent = false
        resetSuccessful = false
    }
    
    /// Handle errors
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
    
    /// Clear error
    func clearError() {
        errorMessage = nil
        showError = false
    }
}
