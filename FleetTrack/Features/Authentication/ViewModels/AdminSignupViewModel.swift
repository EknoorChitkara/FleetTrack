//
//  AdminSignupViewModel.swift
//  authFMS
//
//  Created by Authentication System
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for admin signup flow
@MainActor
class AdminSignupViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Form fields
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    
    // Validation state
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?
    
    // Password strength
    @Published var passwordStrength: ValidationHelpers.PasswordStrength = .veryWeak
    @Published var passwordRequirements: [String: Bool] = [:]
    
    // UI state
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Signup flow state
    @Published var signupSuccessful = false
    @Published var createdUser: User?
    @Published var shouldSetup2FA = false
    
    // MARK: - Services
    
    private let authService = MockAuthService.shared
    private let twoFactorService = MockTwoFactorService.shared
    
    // MARK: - Validation
    
    /// Validate email in real-time
    func validateEmail() {
        emailError = ValidationHelpers.emailValidationMessage(email)
    }
    
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
        validateEmail()
        validatePassword()
        validateConfirmPassword()
        
        return emailError == nil &&
               passwordError == nil &&
               confirmPasswordError == nil &&
               !email.isEmpty &&
               !password.isEmpty &&
               !confirmPassword.isEmpty
    }
    
    // MARK: - Signup
    
    /// Perform admin signup
    func signup() async {
        guard validateForm() else {
            errorMessage = "Please fix the errors above"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.adminSignup(email: email, password: password)
            
            createdUser = user
            signupSuccessful = true
            shouldSetup2FA = true
            
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
        }
    }
    
    // MARK: - 2FA Setup
    
    /// Setup TOTP for newly created admin
    func setupTOTP() async -> TwoFactorAuth? {
        guard let user = createdUser else { return nil }
        
        isLoading = true
        
        do {
            let config = try await twoFactorService.setupTOTP(for: user.id)
            isLoading = false
            return config
        } catch {
            isLoading = false
            handleError(error)
            return nil
        }
    }
    
    /// Verify and enable TOTP
    func verifyAndEnableTOTP(code: String) async -> Bool {
        guard let user = createdUser else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await twoFactorService.verifyAndEnableTOTP(for: user.id, code: code)
            isLoading = false
            return true
        } catch {
            isLoading = false
            handleError(error)
            return false
        }
    }
    
    // MARK: - State Management
    
    /// Reset all state
    func resetState() {
        email = ""
        password = ""
        confirmPassword = ""
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        passwordStrength = .veryWeak
        passwordRequirements = [:]
        isLoading = false
        errorMessage = nil
        showError = false
        signupSuccessful = false
        createdUser = nil
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
