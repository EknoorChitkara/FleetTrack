//
//  AdminCreationViewModel.swift
//  authFMS
//
//  Created by Eknoor on 06/01/26.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for system/super-admin to create new admin accounts
@MainActor
class AdminCreationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Form fields
    @Published var email = ""
    
    // Validation state
    @Published var emailError: String?
    
    // UI state
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Creation flow state
    @Published var creationSuccessful = false
    @Published var setupLink: String?
    @Published var createdUser: User?
    
    // MARK: - Services
    
    private let authService = MockAuthService.shared
    private let emailService = MockEmailService.shared
    
    // MARK: - Validation
    
    /// Validate email in real-time
    func validateEmail() {
        emailError = ValidationHelpers.emailValidationMessage(email)
    }
    
    /// Validate entire form
    private func validateForm() -> Bool {
        validateEmail()
        return emailError == nil && !email.isEmpty
    }
    
    // MARK: - Admin Creation
    
    /// Create admin account and send setup email
    func createAdmin() async {
        guard validateForm() else {
            errorMessage = "Please enter a valid email address"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Create admin account
            let (user, token) = try await authService.createAdminAccount(email: email)
            
            // Send setup email
            try await emailService.sendSetupEmail(to: email, token: token)
            
            // Update state
            createdUser = user
            setupLink = "fleetms://setup?token=\(token)"
            creationSuccessful = true
            
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
        }
    }
    
    // MARK: - State Management
    
    /// Reset all state
    func resetState() {
        email = ""
        emailError = nil
        isLoading = false
        errorMessage = nil
        showError = false
        creationSuccessful = false
        setupLink = nil
        createdUser = nil
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
