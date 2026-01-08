//
//  UserSession.swift
//  authFMS
//
//  Created by Eknoor on 04/01/26.
//

import Foundation

/// User session model for managing authentication sessions
struct UserSession: Identifiable, Codable, Equatable {
    let id: UUID
    let userID: UUID
    let token: String
    let deviceInfo: String
    let expiresAt: Date
    let createdAt: Date
    var lastActivity: Date
    let rememberMe: Bool
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        userID: UUID,
        token: String,
        deviceInfo: String = "iOS Device",
        expiresAt: Date,
        createdAt: Date = Date(),
        lastActivity: Date = Date(),
        rememberMe: Bool = false
    ) {
        self.id = id
        self.userID = userID
        self.token = token
        self.deviceInfo = deviceInfo
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.lastActivity = lastActivity
        self.rememberMe = rememberMe
    }
    
    // MARK: - Computed Properties
    
    /// Check if session is currently valid
    var isValid: Bool {
        return Date() < expiresAt
    }
    
    /// Check if session has expired
    var isExpired: Bool {
        return !isValid
    }
    
    /// Time remaining until expiration (in seconds)
    var timeRemaining: TimeInterval {
        return expiresAt.timeIntervalSinceNow
    }
    
    /// Time remaining in human-readable format
    var timeRemainingFormatted: String {
        let remaining = timeRemaining
        
        if remaining <= 0 {
            return "Expired"
        }
        
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Methods
    
    /// Update last activity timestamp
    mutating func updateActivity() {
        lastActivity = Date()
    }
    
    /// Check if session should be extended (if inactive for less than threshold)
    func shouldExtend(inactivityThreshold: TimeInterval = 3600) -> Bool {
        let inactiveDuration = Date().timeIntervalSince(lastActivity)
        return inactiveDuration < inactivityThreshold && isValid
    }
    
    // MARK: - Static Factory Methods
    
    /// Create a new session with standard expiration (24 hours)
    static func createStandardSession(for userID: UUID) -> UserSession {
        let token = generateSessionToken()
        let expiresAt = Date().addingTimeInterval(24 * 60 * 60) // 24 hours
        
        return UserSession(
            userID: userID,
            token: token,
            expiresAt: expiresAt,
            rememberMe: false
        )
    }
    
    /// Create a new session with extended expiration (30 days) for "Remember Me"
    static func createExtendedSession(for userID: UUID) -> UserSession {
        let token = generateSessionToken()
        let expiresAt = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
        
        return UserSession(
            userID: userID,
            token: token,
            expiresAt: expiresAt,
            rememberMe: true
        )
    }
    
    /// Generate a secure random session token
    private static func generateSessionToken() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let tokenLength = 64
        
        return String((0..<tokenLength).map { _ in
            characters.randomElement()!
        })
    }
}

// MARK: - Session Extensions

extension UserSession {
    /// Create a test session
    static func testSession(for userID: UUID) -> UserSession {
        return createStandardSession(for: userID)
    }
}
