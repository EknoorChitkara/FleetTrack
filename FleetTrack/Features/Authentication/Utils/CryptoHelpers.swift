//
//  CryptoHelpers.swift
//  authFMS
//
//  Created by Eknoor on 04/01/26.
//

import Foundation
import CryptoKit

/// Cryptographic helpers for authentication
struct CryptoHelpers {
    
    // MARK: - Password Hashing
    
    /// Hash a password using SHA256
    static func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Verify password against hash
    static func verifyPassword(_ password: String, hash: String) -> Bool {
        return hashPassword(password) == hash
    }
    
    // MARK: - Token Generation
    
    /// Generate a secure random token
    static func generateToken(length: Int = 64) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    /// Generate a UUID-based token
    static func generateUUIDToken() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
    
    // MARK: - TOTP (Time-based One-Time Password)
    
    /// Generate TOTP code from secret
    static func generateTOTPCode(secret: String, timeInterval: TimeInterval = 30) -> String {
        let counter = UInt64(Date().timeIntervalSince1970 / timeInterval)
        return generateHOTPCode(secret: secret, counter: counter)
    }
    
    /// Generate HOTP code (HMAC-based One-Time Password)
    private static func generateHOTPCode(secret: String, counter: UInt64) -> String {
        // Simplified TOTP implementation for demonstration
        // In production, use a proper TOTP library
        
        let secretData = secret.data(using: .utf8) ?? Data()
        var counterBytes = withUnsafeBytes(of: counter.bigEndian) { Data($0) }
        
        let key = SymmetricKey(data: secretData)
        let hmac = HMAC<SHA256>.authenticationCode(for: counterBytes, using: key)
        
        let hmacData = Data(hmac)
        let offset = Int(hmacData.last! & 0x0f)
        
        let truncatedHash = hmacData.subdata(in: offset..<offset+4)
        let code = truncatedHash.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        
        let otp = (code & 0x7fffffff) % 1000000
        return String(format: "%06d", otp)
    }
    
    /// Verify TOTP code
    static func verifyTOTPCode(_ code: String, secret: String, timeWindow: Int = 1) -> Bool {
        // Check current time window and adjacent windows for clock drift
        for offset in -timeWindow...timeWindow {
            let timeInterval: TimeInterval = 30
            let adjustedTime = Date().addingTimeInterval(Double(offset) * timeInterval)
            let counter = UInt64(adjustedTime.timeIntervalSince1970 / timeInterval)
            let expectedCode = generateHOTPCode(secret: secret, counter: counter)
            
            if code == expectedCode {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - SMS Code Generation
    
    /// Generate a random 6-digit SMS code
    static func generateSMSCode() -> String {
        let code = Int.random(in: 100000...999999)
        return String(code)
    }
    
    // MARK: - Backup Code Generation
    
    /// Generate backup codes
    static func generateBackupCodes(count: Int = 10) -> [String] {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let codeLength = 8
        
        return (0..<count).map { _ in
            String((0..<codeLength).map { _ in characters.randomElement()! })
        }
    }
    
    // MARK: - Password Reset Token
    
    /// Generate password reset token
    static func generatePasswordResetToken() -> String {
        return generateToken(length: 32)
    }
}

// MARK: - TOTP Secret Generation

extension CryptoHelpers {
    /// Generate TOTP secret (Base32 encoded)
    static func generateTOTPSecret() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        let secretLength = 32
        return String((0..<secretLength).map { _ in characters.randomElement()! })
    }
}
