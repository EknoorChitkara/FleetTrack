//
//  TwoFactorAuth.swift
//  authFMS
//
//  Created by Eknoor on 04/01/26.
//

import Foundation

/// Two-factor authentication method
enum TwoFactorMethod: String, Codable, CaseIterable {
    case totp = "TOTP"
    case sms = "SMS"
    
    var displayName: String {
        switch self {
        case .totp:
            return "Authenticator App"
        case .sms:
            return "SMS Code"
        }
    }
    
    var icon: String {
        switch self {
        case .totp:
            return "qrcode"
        case .sms:
            return "message.fill"
        }
    }
}

/// Two-factor authentication configuration model
struct TwoFactorAuth: Identifiable, Codable, Equatable {
    let id: UUID
    let userID: UUID
    let method: TwoFactorMethod
    var secret: String
    var backupCodes: [String]
    var isEnabled: Bool
    let createdAt: Date
    var lastUsed: Date?
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        userID: UUID,
        method: TwoFactorMethod,
        secret: String,
        backupCodes: [String] = [],
        isEnabled: Bool = false,
        createdAt: Date = Date(),
        lastUsed: Date? = nil
    ) {
        self.id = id
        self.userID = userID
        self.method = method
        self.secret = secret
        self.backupCodes = backupCodes
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.lastUsed = lastUsed
    }
    
    // MARK: - Methods
    
    /// Mark 2FA as used
    mutating func markAsUsed() {
        lastUsed = Date()
    }
    
    /// Use a backup code (removes it from available codes)
    mutating func useBackupCode(_ code: String) -> Bool {
        guard let index = backupCodes.firstIndex(of: code) else {
            return false
        }
        
        backupCodes.remove(at: index)
        markAsUsed()
        return true
    }
    
    /// Check if backup codes are running low
    var backupCodesLow: Bool {
        return backupCodes.count <= 3
    }
    
    /// Regenerate backup codes
    mutating func regenerateBackupCodes() {
        backupCodes = Self.generateBackupCodes()
    }
    
    // MARK: - Static Factory Methods
    
    /// Create TOTP configuration
    static func createTOTP(for userID: UUID) -> TwoFactorAuth {
        let secret = generateTOTPSecret()
        let backupCodes = generateBackupCodes()
        
        return TwoFactorAuth(
            userID: userID,
            method: .totp,
            secret: secret,
            backupCodes: backupCodes,
            isEnabled: false
        )
    }
    
    /// Create SMS configuration
    static func createSMS(for userID: UUID) -> TwoFactorAuth {
        let secret = "" // SMS doesn't need a secret
        let backupCodes = generateBackupCodes()
        
        return TwoFactorAuth(
            userID: userID,
            method: .sms,
            secret: secret,
            backupCodes: backupCodes,
            isEnabled: false
        )
    }
    
    /// Generate TOTP secret (base32 encoded)
    private static func generateTOTPSecret() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        let secretLength = 32
        
        return String((0..<secretLength).map { _ in
            characters.randomElement()!
        })
    }
    
    /// Generate backup codes (10 codes, 8 characters each)
    private static func generateBackupCodes(count: Int = 10) -> [String] {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let codeLength = 8
        
        return (0..<count).map { _ in
            String((0..<codeLength).map { _ in
                characters.randomElement()!
            })
        }
    }
}

// MARK: - TwoFactorAuth Extensions

extension TwoFactorAuth {
    /// Get QR code data for TOTP setup
    func getQRCodeData(for email: String, issuer: String = "FleetMS") -> String? {
        guard method == .totp else { return nil }
        
        // Format: otpauth://totp/Issuer:Email?secret=SECRET&issuer=Issuer
        let urlString = "otpauth://totp/\(issuer):\(email)?secret=\(secret)&issuer=\(issuer)"
        return urlString
    }
    
    /// Format backup codes for display (groups of 4 characters)
    var formattedBackupCodes: [String] {
        return backupCodes.map { code in
            let midpoint = code.index(code.startIndex, offsetBy: 4)
            let firstHalf = code[..<midpoint]
            let secondHalf = code[midpoint...]
            return "\(firstHalf)-\(secondHalf)"
        }
    }
}
