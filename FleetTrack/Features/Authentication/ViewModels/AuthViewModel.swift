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
    
    // Success state
    @Published var loginSuccessful = false
    
    // MARK: - Services
    
    private let authService = MockAuthService.shared
    private let twoFactorService = MockTwoFactorService.shared
    private let sessionManager = SessionManager.shared
    
    // MARK: - Admin Authentication
    
    /// Admin login - Step 1: Verify credentials
    func adminLogin(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.adminLogin(email: email, password: password)
            
            // Check if 2FA is enabled
            if user.twoFactorEnabled {
                currentLoginUser = user
                
                // Get 2FA method
                if let config = MockDataStore.shared.find2FAConfig(forUserID: user.id) {
                    twoFactorMethod = config.method
                    
                    // If SMS, send code
                    if config.method == .sms {
                        _ = try await twoFactorService.sendSMSCode(for: user.id)
                    }
                }
                
                isAwaitingTwoFactor = true
            } else {
                // No 2FA, create session directly
                await completeLogin(user: user, rememberMe: false)
            }
            
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
        }
    }
    
    // MARK: - Driver Authentication
    
    /// Driver login - Step 1: Verify credentials
    func driverLogin(phoneNumber: String, employeeID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.driverLogin(
                phoneNumber: phoneNumber,
                employeeID: employeeID
            )
            
            // Send SMS code
            _ = try await twoFactorService.sendSMSCode(for: user.id)
            
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
            
            // Check 2FA method
            if let config = MockDataStore.shared.find2FAConfig(forUserID: user.id) {
                twoFactorMethod = config.method
                
                // If SMS, send code
                if config.method == .sms {
                    _ = try await twoFactorService.sendSMSCode(for: user.id)
                }
            }
            
            currentLoginUser = user
            isAwaitingTwoFactor = true
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
        }
    }
    
    // MARK: - Two-Factor Authentication
    
    /// Verify 2FA code (TOTP or SMS)
    func verifyTwoFactorCode(_ code: String, rememberMe: Bool = false) async {
        guard let user = currentLoginUser else {
            handleError(AuthError.userNotFound)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            var isValid = false
            
            // Verify based on method
            if twoFactorMethod == .totp {
                isValid = try await twoFactorService.verifyTOTPCode(for: user.id, code: code)
            } else if twoFactorMethod == .sms {
                isValid = try await twoFactorService.verifySMSCode(for: user.id, code: code)
            }
            
            if isValid {
                await completeLogin(user: user, rememberMe: rememberMe)
            } else {
                throw AuthError.invalid2FACode
            }
            
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
        }
    }
    
    /// Verify backup code
    func verifyBackupCode(_ code: String, rememberMe: Bool = false) async {
        guard let user = currentLoginUser else {
            handleError(AuthError.userNotFound)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let isValid = try await twoFactorService.verifyBackupCode(for: user.id, code: code)
            
            if isValid {
                await completeLogin(user: user, rememberMe: rememberMe)
            } else {
                throw AuthError.invalid2FACode
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
              twoFactorMethod == .sms else {
            return
        }
        
        isLoading = true
        
        do {
            _ = try await twoFactorService.sendSMSCode(for: user.id)
            isLoading = false
        } catch {
            isLoading = false
            handleError(error)
        }
    }
    
    // MARK: - Session Management
    
    /// Complete login and create session
    private func completeLogin(user: User, rememberMe: Bool) async {
        do {
            let session = try await authService.createSession(for: user, rememberMe: rememberMe)
            sessionManager.setSession(user: user, session: session)
            
            // Reset state
            isAwaitingTwoFactor = false
            currentLoginUser = nil
            twoFactorMethod = nil
            loginSuccessful = true
        } catch {
            handleError(error)
        }
    }
    
    /// Logout
    func logout() async {
        isLoading = true
        await sessionManager.logout()
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
