//
//  User.swift
//  authFMS
//
//  Created by Eknoor on 04/01/26.
//

import Foundation

/// User role enumeration for Fleet Management System
enum UserRole: String, Codable, CaseIterable {
    case admin = "Fleet Manager"
    case driver = "Driver"
    case maintenanceManager = "Maintenance Manager"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .admin:
            return "person.badge.key.fill"
        case .driver:
            return "car.fill"
        case .maintenanceManager:
            return "wrench.and.screwdriver.fill"
        }
    }
}

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

/// Main user model for authentication system
struct User: Identifiable, Codable, Equatable {
    let id: UUID
    let role: UserRole
    
    // Role-specific credentials
    var email: String?              // Only for admin
    var phoneNumber: String?        // Only for driver
    var employeeID: String?         // For driver & maintenance manager
    
    // Security
    var passwordHash: String?
    var passwordSetAt: Date?
    var isActive: Bool
    var isVerified: Bool
    
    // Timestamps
    var createdAt: Date
    var lastLogin: Date?
    
    // Account protection
    var failedLoginAttempts: Int
    var accountLockedUntil: Date?
    
    // Two-factor authentication
    var twoFactorEnabled: Bool
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        role: UserRole,
        email: String? = nil,
        phoneNumber: String? = nil,
        employeeID: String? = nil,
        passwordHash: String? = nil,
        passwordSetAt: Date? = nil,
        isActive: Bool = true,
        isVerified: Bool = false,
        createdAt: Date = Date(),
        lastLogin: Date? = nil,
        failedLoginAttempts: Int = 0,
        accountLockedUntil: Date? = nil,
        twoFactorEnabled: Bool = false
    ) {
        self.id = id
        self.role = role
        self.email = email
        self.phoneNumber = phoneNumber
        self.employeeID = employeeID
        self.passwordHash = passwordHash
        self.passwordSetAt = passwordSetAt
        self.isActive = isActive
        self.isVerified = isVerified
        self.createdAt = createdAt
        self.lastLogin = lastLogin
        self.failedLoginAttempts = failedLoginAttempts
        self.accountLockedUntil = accountLockedUntil
        self.twoFactorEnabled = twoFactorEnabled
    }
    
    // MARK: - Computed Properties
    
    /// Check if account is currently locked
    var isLocked: Bool {
        guard let lockUntil = accountLockedUntil else { return false }
        return Date() < lockUntil
    }
    
    /// Display name based on role and credentials
    var displayName: String {
        switch role {
        case .admin:
            return email ?? "Admin"
        case .driver:
            return "Driver \(employeeID ?? "")"
        case .maintenanceManager:
            return "Maintenance \(employeeID ?? "")"
        }
    }
    
    /// Primary credential for login (role-dependent)
    var primaryCredential: String? {
        switch role {
        case .admin:
            return email
        case .driver:
            return phoneNumber
        case .maintenanceManager:
            return employeeID
        }
    }
    
    /// Check if user needs to complete password setup
    var needsPasswordSetup: Bool {
        return passwordHash == nil
    }
    
    // MARK: - Methods
    
    /// Increment failed login attempts
    mutating func incrementFailedAttempts() {
        failedLoginAttempts += 1
        
        // Lock account after 5 failed attempts
        if failedLoginAttempts >= 5 {
            accountLockedUntil = Date().addingTimeInterval(30 * 60) // 30 minutes
        }
    }
    
    /// Reset failed login attempts after successful login
    mutating func resetFailedAttempts() {
        failedLoginAttempts = 0
        accountLockedUntil = nil
    }
    
    /// Update last login timestamp
    mutating func updateLastLogin() {
        lastLogin = Date()
    }
    
    /// Validate if user can attempt login
    func canAttemptLogin() -> (canLogin: Bool, reason: String?) {
        if !isActive {
            return (false, "Account is deactivated")
        }
        
        if isLocked {
            let remainingTime = Int(accountLockedUntil!.timeIntervalSinceNow / 60)
            return (false, "Account is locked. Try again in \(remainingTime) minutes")
        }
        
        return (true, nil)
    }
}

// MARK: - User Extensions

extension User {
    /// Create a test admin user
    static func testAdmin() -> User {
        User(
            role: .admin,
            email: "admin@fleetms.com",
            passwordHash: "hashed_password_placeholder",
            isVerified: true,
            twoFactorEnabled: true
        )
    }
    
    /// Create a test driver user
    static func testDriver() -> User {
        User(
            role: .driver,
            phoneNumber: "+15551234567",
            employeeID: "DRV001",
            passwordHash: "hashed_Driver@123",
            isVerified: true,
            twoFactorEnabled: true
        )
    }
    
    /// Create a test maintenance manager user
    static func testMaintenance() -> User {
        User(
            role: .maintenanceManager,
            employeeID: "MNT001",
            passwordHash: "hashed_Maint@123",
            isVerified: true,
            twoFactorEnabled: true
        )
    }
}
