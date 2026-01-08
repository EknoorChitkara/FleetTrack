//
//  SetupToken.swift
//  authFMS
//
//  Created by Eknoor on 06/01/26.
//

import Foundation

/// Account setup token for password creation
struct SetupToken: Identifiable, Codable, Equatable {
    let id: UUID
    let userID: UUID
    let token: String
    let expiresAt: Date
    let createdAt: Date
    var isUsed: Bool
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        userID: UUID,
        token: String,
        expiresAt: Date,
        createdAt: Date = Date(),
        isUsed: Bool = false
    ) {
        self.id = id
        self.userID = userID
        self.token = token
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.isUsed = isUsed
    }
    
    // MARK: - Computed Properties
    
    /// Check if token is currently valid
    var isValid: Bool {
        return !isUsed && Date() < expiresAt
    }
    
    /// Check if token has expired
    var isExpired: Bool {
        return Date() >= expiresAt
    }
    
    /// Time remaining until expiration (in seconds)
    var timeRemaining: TimeInterval {
        return expiresAt.timeIntervalSinceNow
    }
    
    // MARK: - Methods
    
    /// Mark token as used
    mutating func markAsUsed() {
        isUsed = true
    }
    
    // MARK: - Static Factory Methods
    
    /// Create a new setup token with 24-hour expiration
    static func create(for userID: UUID) -> SetupToken {
        let token = generateToken()
        let expiresAt = Date().addingTimeInterval(24 * 60 * 60) // 24 hours
        
        return SetupToken(
            userID: userID,
            token: token,
            expiresAt: expiresAt
        )
    }
    
    /// Generate a secure random token
    private static func generateToken() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let tokenLength = 64
        
        return String((0..<tokenLength).map { _ in
            characters.randomElement()!
        })
    }
}

// MARK: - SetupToken Extensions

extension SetupToken {
    /// Create a test setup token
    static func testToken(for userID: UUID) -> SetupToken {
        return create(for: userID)
    }
}
