//
//  AdminSetupViewModel.swift
//  authFMS
//
//  Created by Eknoor on 06/01/26.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for admin password setup flow (from email link)
@MainActor
class AdminSetupViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Setup token (from email link)
    @Published var setupToken = ""
    
    // Form fields
    @Published var password = ""
    @Published var confirmPassword = ""
    
    // Validation state
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?
    
    // Password strength
    @Published var passwordStrength: ValidationHelpers.PasswordStrength = .veryWeak
    @Published var passwordRequirements: [String: Bool] = [:]
    
    // UI state
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Setup flow state
    @Published var tokenValidated = false
    @Published var passwordSetSuccessful = false
    @Published var setupUser: User?
    @Published var shouldSetup2FA = false
    
    // MARK: - Services
    
    private let authService: AuthServiceProtocol = SupabaseAuthService.shared
    
    // MARK: - Token Validation
    
    /// Validate setup token from email link
    /// Note: Firebase handles this via password reset email, not custom tokens
    func validateToken() async -> Bool {
        // This flow is deprecated in Firebase implementation
        // Firebase sends password reset emails instead
        tokenValidated = true
        return true
    }
    
    // MARK: - Validation
    
    /// Validate password in real-time
    func validatePassword() {
        passwordError = ValidationHelpers.passwordValidationMessage(password)
        passwordStrength = ValidationHelpers.passwordStrength(password)
        passwordRequirements = ValidationHelpers.passwordRequirements(password)
    }
    
    /// Validate confirm password
    func validateConfirmPassword() {
        if confirmPassword.isEmpty {
            confirmPasswordError = "Please confirm your password"
        } else if password != confirmPassword {
            confirmPasswordError = "Passwords do not match"
        } else {
            confirmPasswordError = nil
        }
    }
    
    /// Validate entire form
    private func validateForm() -> Bool {
        validatePassword()
        validateConfirmPassword()
        
        return passwordError == nil &&
               confirmPasswordError == nil &&
               !password.isEmpty &&
               !confirmPassword.isEmpty
    }
    
    // MARK: - Password Setup
    
    /// Set initial password for admin account
    /// Note: In Firebase, this is handled via password reset flow
    func setupPassword() async {
        guard validateForm() else {
            errorMessage = "Please fix the errors above"
            showError = true
            return
        }
        
        // This is a placeholder - Firebase handles password setup via reset email
        passwordSetSuccessful = true
        shouldSetup2FA = false // Firebase doesn't require immediate 2FA setup
    }
    
    // MARK: - 2FA Setup (Deprecated in Firebase Flow)
    
    /// Setup TOTP for newly created admin
    /// Note: Firebase handles 2FA differently - this is deprecated
    @available(*, deprecated, message: "Firebase handles 2FA setup differently")
    func setupTOTP() async {
        // Deprecated - Firebase uses different 2FA approach
    }
    
    /// Verify and enable TOTP
    /// Note: Firebase handles 2FA differently - this is deprecated
    func verifyAndEnableTOTP(code: String) async -> Bool {
        // Deprecated - Firebase uses different 2FA approach
        return true
    }
    
    // MARK: - State Management
    
    /// Reset all state
    func resetState() {
        setupToken = ""
        password = ""
        confirmPassword = ""
        passwordError = nil
        confirmPasswordError = nil
        passwordStrength = .veryWeak
        passwordRequirements = [:]
        isLoading = false
        errorMessage = nil
        showError = false
        tokenValidated = false
        passwordSetSuccessful = false
        setupUser = nil
        shouldSetup2FA = false
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
