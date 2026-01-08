//
//  MockTwoFactorService.swift
//  authFMS
//
//  Created by Eknoor on 04/01/26.
//

import Foundation

/// Mock two-factor authentication service
class MockTwoFactorService {
    
    static let shared = MockTwoFactorService()
    private let dataStore = MockDataStore.shared
    
    // Store generated SMS codes temporarily (in production, this would be server-side)
    private var smsCodeCache: [UUID: (code: String, expiresAt: Date)] = [:]
    
    private init() {}
    
    // MARK: - 2FA Setup
    
    /// Setup TOTP for user
    func setupTOTP(for userID: UUID) async throws -> TwoFactorAuth {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Check if 2FA already exists
        if let existing = dataStore.find2FAConfig(forUserID: userID) {
            return existing
        }
        
        // Create new TOTP config
        let totpConfig = TwoFactorAuth.createTOTP(for: userID)
        dataStore.create2FAConfig(totpConfig)
        
        print("✅ TOTP setup initiated for user")
        return totpConfig
    }
    
    /// Setup SMS for user
    func setupSMS(for userID: UUID) async throws -> TwoFactorAuth {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Check if 2FA already exists
        if let existing = dataStore.find2FAConfig(forUserID: userID) {
            return existing
        }
        
        // Create new SMS config
        let smsConfig = TwoFactorAuth.createSMS(for: userID)
        dataStore.create2FAConfig(smsConfig)
        
        print("✅ SMS 2FA setup initiated for user")
        return smsConfig
    }
    
    // MARK: - TOTP Operations
    
    /// Verify TOTP code and enable 2FA
    func verifyAndEnableTOTP(for userID: UUID, code: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        guard var config = dataStore.find2FAConfig(forUserID: userID) else {
            throw TwoFactorError.configNotFound
        }
        
        guard config.method == .totp else {
            throw TwoFactorError.wrongMethod
        }
        
        // Verify TOTP code
        guard CryptoHelpers.verifyTOTPCode(code, secret: config.secret) else {
            throw TwoFactorError.invalidCode
        }
        
        // Enable 2FA
        config.isEnabled = true
        config.markAsUsed()
        dataStore.update2FAConfig(config)
        
        // Update user
        if var user = dataStore.findUser(byID: userID) {
            user.twoFactorEnabled = true
            dataStore.updateUser(user)
        }
        
        print("✅ TOTP enabled for user")
    }
    
    /// Verify TOTP code for login
    func verifyTOTPCode(for userID: UUID, code: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        guard let config = dataStore.find2FAConfig(forUserID: userID) else {
            throw TwoFactorError.configNotFound
        }
        
        guard config.isEnabled else {
            throw TwoFactorError.notEnabled
        }
        
        guard config.method == .totp else {
            throw TwoFactorError.wrongMethod
        }
        
        // Verify code
        let isValid = CryptoHelpers.verifyTOTPCode(code, secret: config.secret)
        
        if isValid {
            var updatedConfig = config
            updatedConfig.markAsUsed()
            dataStore.update2FAConfig(updatedConfig)
            print("✅ TOTP code verified")
        } else {
            print("❌ Invalid TOTP code")
        }
        
        return isValid
    }
    
    // MARK: - SMS Operations
    
    /// Send SMS code
    func sendSMSCode(for userID: UUID) async throws -> String {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard let user = dataStore.findUser(byID: userID) else {
            throw TwoFactorError.userNotFound
        }
        
        guard let phoneNumber = user.phoneNumber else {
            throw TwoFactorError.phoneNotFound
        }
        
        // Generate SMS code
        let code = CryptoHelpers.generateSMSCode()
        let expiresAt = Date().addingTimeInterval(300) // 5 minutes
        
        // Cache code
        smsCodeCache[userID] = (code: code, expiresAt: expiresAt)
        
        print("✅ SMS code sent to \(phoneNumber): \(code)")
        print("   (In production, this would be sent via SMS provider)")
        
        return code
    }
    
    /// Verify SMS code
    func verifySMSCode(for userID: UUID, code: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        guard let cached = smsCodeCache[userID] else {
            throw TwoFactorError.codeNotFound
        }
        
        // Check expiration
        guard Date() < cached.expiresAt else {
            smsCodeCache.removeValue(forKey: userID)
            throw TwoFactorError.codeExpired
        }
        
        // Verify code
        let isValid = code == cached.code
        
        if isValid {
            // Remove used code
            smsCodeCache.removeValue(forKey: userID)
            
            // Update config
            if var config = dataStore.find2FAConfig(forUserID: userID) {
                config.markAsUsed()
                dataStore.update2FAConfig(config)
            }
            
            print("✅ SMS code verified")
        } else {
            print("❌ Invalid SMS code")
        }
        
        return isValid
    }
    
    // MARK: - Backup Codes
    
    /// Verify backup code
    func verifyBackupCode(for userID: UUID, code: String) async throws -> Bool {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 600_000_000)
        
        guard var config = dataStore.find2FAConfig(forUserID: userID) else {
            throw TwoFactorError.configNotFound
        }
        
        guard config.isEnabled else {
            throw TwoFactorError.notEnabled
        }
        
        // Try to use backup code
        let isValid = config.useBackupCode(code.uppercased())
        
        if isValid {
            dataStore.update2FAConfig(config)
            print("✅ Backup code verified and consumed")
            
            // Warn if running low
            if config.backupCodesLow {
                print("⚠️ Backup codes running low (\(config.backupCodes.count) remaining)")
            }
        } else {
            print("❌ Invalid backup code")
        }
        
        return isValid
    }
    
    /// Regenerate backup codes
    func regenerateBackupCodes(for userID: UUID) async throws -> [String] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        guard var config = dataStore.find2FAConfig(forUserID: userID) else {
            throw TwoFactorError.configNotFound
        }
        
        config.regenerateBackupCodes()
        dataStore.update2FAConfig(config)
        
        print("✅ Backup codes regenerated")
        return config.backupCodes
    }
    
    // MARK: - Disable 2FA
    
    /// Disable 2FA for user
    func disable2FA(for userID: UUID) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard var config = dataStore.find2FAConfig(forUserID: userID) else {
            throw TwoFactorError.configNotFound
        }
        
        config.isEnabled = false
        dataStore.update2FAConfig(config)
        
        // Update user
        if var user = dataStore.findUser(byID: userID) {
            user.twoFactorEnabled = false
            dataStore.updateUser(user)
        }
        
        print("✅ 2FA disabled for user")
    }
}

// MARK: - Two Factor Errors

enum TwoFactorError: LocalizedError {
    case configNotFound
    case wrongMethod
    case invalidCode
    case notEnabled
    case userNotFound
    case phoneNotFound
    case codeNotFound
    case codeExpired
    
    var errorDescription: String? {
        switch self {
        case .configNotFound:
            return "2FA configuration not found"
        case .wrongMethod:
            return "Wrong 2FA method"
        case .invalidCode:
            return "Invalid verification code"
        case .notEnabled:
            return "2FA is not enabled"
        case .userNotFound:
            return "User not found"
        case .phoneNotFound:
            return "Phone number not found"
        case .codeNotFound:
            return "Verification code not found"
        case .codeExpired:
            return "Verification code has expired"
        }
    }
}
