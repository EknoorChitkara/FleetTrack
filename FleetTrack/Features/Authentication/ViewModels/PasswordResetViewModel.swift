//
//  PasswordResetViewModel.swift
//  FleetTrack
//
//  Created by Firebase Integration
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for in-app password reset flow (via deep link)
@MainActor
class PasswordResetViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var oobCode: String = ""
    @Published var email: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    
    // Validation
    @Published var newPasswordError: String?
    @Published var confirmPasswordError: String?
    @Published var passwordStrength: ValidationHelpers.PasswordStrength = .veryWeak
    
    // UI State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var resetSuccessful = false
    
    // MARK: - Initialization
    
    /// Initialize with oobCode from deep link
    func initialize(oobCode: String) async {
        self.oobCode = oobCode
        isLoading = true
        
        do {
            // Verify code and get associated email
            let email = try await DeepLinkHandler.verifyPasswordResetCode(oobCode)
            self.email = email
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Invalid or expired reset link"
            showError = true
        }
    }
    
    // MARK: - Validation
    
    func validateNewPassword() {
        newPasswordError = ValidationHelpers.passwordValidationMessage(newPassword)
        passwordStrength = ValidationHelpers.passwordStrength(newPassword)
    }
    
    func validateConfirmPassword() {
        if confirmPassword.isEmpty {
            confirmPasswordError = "Please confirm your password"
        } else if newPassword != confirmPassword {
            confirmPasswordError = "Passwords do not match"
        } else {
            confirmPasswordError = nil
        }
    }
    
    // MARK: - Password Reset
    
    func resetPassword() async {
        validateNewPassword()
        validateConfirmPassword()
        
        guard newPasswordError == nil,
              confirmPasswordError == nil,
              !newPassword.isEmpty else {
            errorMessage = "Please fix the errors above"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await DeepLinkHandler.confirmPasswordReset(
                code: oobCode,
                newPassword: newPassword
            )
            
            resetSuccessful = true
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // MARK: - State Management
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
}
