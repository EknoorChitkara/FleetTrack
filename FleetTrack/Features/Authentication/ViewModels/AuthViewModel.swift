//
//  AuthViewModel.swift
//  authFMS
//
//  Created by Authentication System
//

import Foundation
import SwiftUI
import Combine

/// Centralized authentication ViewModel for all user roles
@MainActor
class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Login state
    @Published var isAwaitingTwoFactor = false
    @Published var currentLoginUser: User?
    @Published var twoFactorMethod: TwoFactorMethod?
    @Published var verificationID: String? // Added for SMS flow
    @Published var isAuthenticated = false
    
    // Success state
    @Published var loginSuccessful = false
    
    // MARK: - Services
    
    private let authService: AuthServiceProtocol = SupabaseAuthService.shared
    private let sessionManager = SessionManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Sync auth state with session manager
        sessionManager.$isAuthenticated
            .receive(on: RunLoop.main)
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Admin Authentication
    
    /// Admin login - Step 1: Verify credentials
    func adminLogin(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.adminLogin(email: email, password: password)
            await completeLogin(user: user, rememberMe: false)
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
        }
    }
    
    // MARK: - Driver Authentication
    
    /// Driver login - Step 1: Verify credentials and send SMS
    func driverLogin(phoneNumber: String, employeeID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Validate credentials existence
            let user = try await authService.driverLogin(
                phoneNumber: phoneNumber,
                employeeID: employeeID
            )
            
            // 2. Send SMS code
            let vid = try await authService.sendDriverSMSCode(phoneNumber: phoneNumber)
            self.verificationID = vid
            
            currentLoginUser = user
            twoFactorMethod = .sms
            isAwaitingTwoFactor = true
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
        }
    }
    
    // MARK: - Maintenance Manager Authentication
    
    /// Maintenance manager login - Step 1: Verify credentials
    func maintenanceLogin(employeeID: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.maintenanceLogin(
                employeeID: employeeID,
                password: password
            )
            await completeLogin(user: user, rememberMe: false)
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
        }
    }
    
    // MARK: - Two-Factor Authentication
    
    /// Verify 2FA code (SMS only for now)
    func verifyTwoFactorCode(_ code: String, rememberMe: Bool = false) async {
        guard let user = currentLoginUser else {
            handleError(AuthError.userNotFound)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Verify based on method
            if twoFactorMethod == .sms {
                guard let employeeID = user.employeeID, let vid = verificationID else {
                   throw AuthError.invalidCredentials
                }
                
                // Login via SMS verification
                let verifiedUser = try await authService.verifyDriverSMSCode(
                    verificationID: vid,
                    code: code,
                    employeeID: employeeID
                )
                await completeLogin(user: verifiedUser, rememberMe: rememberMe)
            } else {
                throw AuthError.invalidCredentials
            }
            
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
        }
    }
    
    /// Resend 2FA code (SMS only)
    func resendTwoFactorCode() async {
        guard let user = currentLoginUser,
              let phoneNumber = user.phoneNumber,
              twoFactorMethod == .sms else {
            return
        }
        
        isLoading = true
        
        do {
            let vid = try await authService.sendDriverSMSCode(phoneNumber: phoneNumber)
            self.verificationID = vid
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
        }
    }
    
    // MARK: - Session Management
    
    /// Complete login and update session
    private func completeLogin(user: User, rememberMe: Bool) async {
        sessionManager.setUser(user)
        
        // Reset state
        isAwaitingTwoFactor = false
        currentLoginUser = nil
        twoFactorMethod = nil
        verificationID = nil
        loginSuccessful = true
    }
    
    /// Logout
    func logout() async {
        isLoading = true
        try? await authService.logout()
        sessionManager.clearSession()
        isLoading = false
        resetState()
    }
    
    // MARK: - State Management
    
    /// Reset all state
    func resetState() {
        isLoading = false
        errorMessage = nil
        showError = false
        isAwaitingTwoFactor = false
        currentLoginUser = nil
        twoFactorMethod = nil
        verificationID = nil
        loginSuccessful = false
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

enum AuthError: LocalizedError {
    case userNotFound
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .invalidCredentials:
            return "Invalid credentials"
        }
    }
}

enum TwoFactorMethod: String, Codable, CaseIterable {
    case sms
    case email
}
