//
//  MockEmailService.swift
//  authFMS
//
//  Created by Eknoor on 06/01/26.
//

import Foundation

/// Mock email service for simulating email sending
class MockEmailService {
    
    static let shared = MockEmailService()
    
    private init() {}
    
    // MARK: - Setup Email
    
    /// Send account setup email with password creation link
    func sendSetupEmail(to email: String, token: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let setupLink = "fleetms://setup?token=\(token)"
        
        print("📧 ========== EMAIL SENT ==========")
        print("To: \(email)")
        print("Subject: Complete Your Fleet Manager Account Setup")
        print("")
        print("Welcome to Fleet Management System!")
        print("")
        print("Your admin account has been created. Please complete your")
        print("account setup by creating a password:")
        print("")
        print("Setup Link: \(setupLink)")
        print("")
        print("This link expires in 24 hours.")
        print("")
        print("If you did not request this account, please ignore this email.")
        print("==================================")
    }
    
    // MARK: - Password Reset Email
    
    /// Send password reset email (for existing functionality)
    func sendPasswordResetEmail(to email: String, token: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let resetLink = "fleetms://reset-password?token=\(token)"
        
        print("📧 ========== EMAIL SENT ==========")
        print("To: \(email)")
        print("Subject: Password Reset Request")
        print("")
        print("You requested to reset your password.")
        print("")
        print("Reset Link: \(resetLink)")
        print("")
        print("This link expires in 1 hour.")
        print("")
        print("If you did not request this, please ignore this email.")
        print("==================================")
    }
    
    // MARK: - 2FA Email
    
    /// Send 2FA setup confirmation email
    func send2FAEnabledEmail(to email: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        print("📧 ========== EMAIL SENT ==========")
        print("To: \(email)")
        print("Subject: Two-Factor Authentication Enabled")
        print("")
        print("Two-factor authentication has been enabled on your account.")
        print("")
        print("If you did not enable this, please contact support immediately.")
        print("==================================")
    }
}
