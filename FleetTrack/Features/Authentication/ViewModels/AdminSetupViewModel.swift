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
    
    private let authService = MockAuthService.shared
    private let twoFactorService = MockTwoFactorService.shared
    
    // MARK: - Token Validation
    
    /// Validate setup token from email link
    func validateToken() async -> Bool {
        guard !setupToken.isEmpty else {
            errorMessage = "Invalid setup link"
            showError = true
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.verifySetupToken(setupToken)
            
            setupUser = user
            tokenValidated = true
            isLoading = false
            return true
        } catch {
            isLoading = false
            handleError(error)
            return false
        }
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
    func setupPassword() async {
        guard validateForm() else {
            errorMessage = "Please fix the errors above"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.setInitialPassword(token: setupToken, password: password)
            
            setupUser = user
            passwordSetSuccessful = true
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
        guard let user = setupUser else { return nil }
        
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
        guard let user = setupUser else { return false }
        
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
