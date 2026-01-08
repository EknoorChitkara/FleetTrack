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
    
    // MARK: - Services
    
    private let authService: AuthServiceProtocol = FirebaseAuthService.shared
    
    // MARK: - Validation
    
    /// Validate email
    func validateEmail() {
        emailError = ValidationHelpers.emailValidationMessage(email)
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
            // Firebase sends the email directly. We don't get a token back to handle manually.
            _ = try await authService.requestPasswordReset(email: email)
            
            resetEmailSent = true
            errorMessage = "Password reset email sent. Please check your inbox."
            showError = true // Showing as info/success message in this context for now
            
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
        }
    }
    
    /// Step 2: Reset password with token (Not used in Firebase flow)
    /// Firebase handles the actual reset on a web page, not in-app usually, unless using dynamic links.
    /// For this prototype, we'll mark this as not supported or just return success to simulate.
    func resetPassword() async {
        // Firebase Auth standard flow handles this out of app.
        // We will just simulate success if called, or deprecate this method.
        resetSuccessful = true
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
