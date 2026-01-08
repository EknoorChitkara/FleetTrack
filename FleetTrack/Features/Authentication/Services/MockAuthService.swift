//
//  MockAuthService.swift
//  authFMS
//
//  Created by Eknoor on 04/01/26.
//

import Foundation

/// Mock authentication service simulating backend API
class MockAuthService {
    
    static let shared = MockAuthService()
    private let dataStore = MockDataStore.shared
    private let emailService = MockEmailService.shared
    
    private init() {}
    
    // MARK: - Admin Account Creation (System/Super-Admin)
    
    /// Create admin account without password (system/super-admin only)
    func createAdminAccount(email: String) async throws -> (user: User, setupToken: String) {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Validate input
        guard ValidationHelpers.isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        // Check if email already exists
        if dataStore.findUser(byEmail: email) != nil {
            throw AuthError.emailAlreadyExists
        }
        
        // Create new admin user WITHOUT password
        let user = User(
            role: .admin,
            email: email,
            passwordHash: nil,  // No password yet
            isVerified: false,  // Not verified until password set
            twoFactorEnabled: false
        )
        
        guard dataStore.createUser(user) else {
            throw AuthError.userCreationFailed
        }
        
        // Generate setup token
        let setupToken = dataStore.createSetupToken(forUserID: user.id)
        
        print("✅ Admin account created: \(email)")
        print("📧 Setup link: fleetms://setup?token=\(setupToken)")
        
        return (user, setupToken)
    }
    
    // MARK: - Admin Password Setup
    
    /// Verify setup token is valid
    func verifySetupToken(_ token: String) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        guard let userID = dataStore.validateSetupToken(token) else {
            throw AuthError.invalidSetupToken
        }
        
        guard let user = dataStore.findUser(byID: userID) else {
            throw AuthError.userNotFound
        }
        
        guard user.needsPasswordSetup else {
            throw AuthError.passwordAlreadySet
        }
        
        print("✅ Setup token verified for: \(user.email ?? "unknown")")
        return user
    }
    
    /// Set initial password for admin account
    func setInitialPassword(token: String, password: String) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Validate password
        guard ValidationHelpers.isValidPassword(password) else {
            throw AuthError.weakPassword
        }
        
        // Validate token
        guard let userID = dataStore.validateSetupToken(token) else {
            throw AuthError.invalidSetupToken
        }
        
        guard var user = dataStore.findUser(byID: userID) else {
            throw AuthError.userNotFound
        }
        
        guard user.needsPasswordSetup else {
            throw AuthError.passwordAlreadySet
        }
        
        // Set password
        user.passwordHash = CryptoHelpers.hashPassword(password)
        user.passwordSetAt = Date()
        user.isVerified = true
        dataStore.updateUser(user)
        
        // Invalidate setup token
        dataStore.useSetupToken(token)
        
        print("✅ Password set for: \(user.displayName)")
        return user
    }
    
    // MARK: - Admin Authentication
    
    /// Admin login (step 1: credentials)
    func adminLogin(email: String, password: String) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        // Find user
        guard var user = dataStore.findUser(byEmail: email) else {
            throw AuthError.invalidCredentials
        }
        
        // Check if password has been set
        guard !user.needsPasswordSetup else {
            throw AuthError.passwordNotSet
        }
        
        // Check if account can login
        let (canLogin, reason) = user.canAttemptLogin()
        if !canLogin {
            throw AuthError.accountLocked(reason: reason ?? "Account locked")
        }
        
        // Verify password
        guard let passwordHash = user.passwordHash,
              CryptoHelpers.verifyPassword(password, hash: passwordHash) else {
            user.incrementFailedAttempts()
            dataStore.updateUser(user)
            throw AuthError.invalidCredentials
        }
        
        // Reset failed attempts on successful login
        user.resetFailedAttempts()
        dataStore.updateUser(user)
        
        print("✅ Admin credentials verified: \(email)")
        return user
    }
    
    // MARK: - Driver Authentication
    
    /// Driver login (step 1: credentials)
    func driverLogin(phoneNumber: String, employeeID: String) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        // Find user by phone
        guard var user = dataStore.findUser(byPhone: phoneNumber) else {
            throw AuthError.invalidCredentials
        }
        
        // Verify employee ID matches
        guard user.employeeID?.uppercased() == employeeID.uppercased() else {
            user.incrementFailedAttempts()
            dataStore.updateUser(user)
            throw AuthError.invalidCredentials
        }
        
        // Check if account can login
        let (canLogin, reason) = user.canAttemptLogin()
        if !canLogin {
            throw AuthError.accountLocked(reason: reason ?? "Account locked")
        }
        
        // Reset failed attempts
        user.resetFailedAttempts()
        dataStore.updateUser(user)
        
        print("✅ Driver credentials verified: \(phoneNumber)")
        return user
    }
    
    // MARK: - Maintenance Manager Authentication
    
    /// Maintenance manager login (step 1: credentials)
    func maintenanceLogin(employeeID: String, password: String) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        
        // Find user by employee ID
        guard var user = dataStore.findUser(byEmployeeID: employeeID) else {
            throw AuthError.invalidCredentials
        }
        
        // Verify role
        guard user.role == .maintenanceManager else {
            throw AuthError.invalidCredentials
        }
        
        // Check if account can login
        let (canLogin, reason) = user.canAttemptLogin()
        if !canLogin {
            throw AuthError.accountLocked(reason: reason ?? "Account locked")
        }
        
        // Verify password
        if !CryptoHelpers.verifyPassword(password, hash: user.passwordHash) {
            user.incrementFailedAttempts()
            dataStore.updateUser(user)
            throw AuthError.invalidCredentials
        }
        
        // Reset failed attempts
        user.resetFailedAttempts()
        dataStore.updateUser(user)
        
        print("✅ Maintenance credentials verified: \(employeeID)")
        return user
    }
    
    // MARK: - Session Management
    
    /// Create session after successful 2FA
    func createSession(for user: User, rememberMe: Bool = false) async throws -> UserSession {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let session = rememberMe
            ? UserSession.createExtendedSession(for: user.id)
            : UserSession.createStandardSession(for: user.id)
        
        dataStore.createSession(session)
        
        // Update user's last login
        var updatedUser = user
        updatedUser.updateLastLogin()
        dataStore.updateUser(updatedUser)
        
        print("✅ Session created for user: \(user.displayName)")
        return session
    }
    
    /// Validate session token
    func validateSession(token: String) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard let session = dataStore.findSession(byToken: token) else {
            throw AuthError.invalidSession
        }
        
        guard session.isValid else {
            throw AuthError.sessionExpired
        }
        
        guard let user = dataStore.findUser(byID: session.userID) else {
            throw AuthError.userNotFound
        }
        
        // Update session activity
        var updatedSession = session
        updatedSession.updateActivity()
        dataStore.updateSession(updatedSession)
        
        return user
    }
    
    /// Logout (invalidate session)
    func logout(token: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        
        dataStore.deleteSession(byToken: token)
        print("✅ Session invalidated")
    }
    
    /// Logout from all devices
    func logoutAllDevices(userID: UUID) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        dataStore.deleteAllSessions(forUserID: userID)
        print("✅ All sessions invalidated for user")
    }
    
    // MARK: - Password Management
    
    /// Request password reset
    func requestPasswordReset(email: String) async throws -> String {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard let user = dataStore.findUser(byEmail: email) else {
            // Don't reveal if email exists (security best practice)
            print("⚠️ Password reset requested for non-existent email")
            return "mock_token_for_nonexistent_email"
        }
        
        let token = dataStore.createPasswordResetToken(forUserID: user.id)
        print("✅ Password reset token created for: \(email)")
        print("   Reset link: fleetms://reset-password?token=\(token)")
        
        return token
    }
    
    /// Reset password with token
    func resetPassword(token: String, newPassword: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard ValidationHelpers.isValidPassword(newPassword) else {
            throw AuthError.weakPassword
        }
        
        guard let userID = dataStore.validatePasswordResetToken(token) else {
            throw AuthError.invalidResetToken
        }
        
        guard var user = dataStore.findUser(byID: userID) else {
            throw AuthError.userNotFound
        }
        
        // Update password
        user.passwordHash = CryptoHelpers.hashPassword(newPassword)
        dataStore.updateUser(user)
        
        // Invalidate token
        dataStore.usePasswordResetToken(token)
        
        // Logout all sessions for security
        dataStore.deleteAllSessions(forUserID: userID)
        
        print("✅ Password reset successful for user: \(user.displayName)")
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyExists
    case userCreationFailed
    case invalidCredentials
    case accountLocked(reason: String)
    case invalidSession
    case sessionExpired
    case userNotFound
    case invalidResetToken
    case twoFactorRequired
    case invalid2FACode
    case invalidSetupToken
    case setupTokenExpired
    case passwordAlreadySet
    case passwordNotSet
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 8 characters with uppercase, lowercase, number, and special character"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .userCreationFailed:
            return "Failed to create user account"
        case .invalidCredentials:
            return "Invalid credentials. Please try again."
        case .accountLocked(let reason):
            return reason
        case .invalidSession:
            return "Invalid session. Please login again."
        case .sessionExpired:
            return "Your session has expired. Please login again."
        case .userNotFound:
            return "User not found"
        case .invalidResetToken:
            return "Invalid or expired reset token"
        case .twoFactorRequired:
            return "Two-factor authentication required"
        case .invalid2FACode:
            return "Invalid verification code"
        case .invalidSetupToken:
            return "Invalid or expired setup token"
        case .setupTokenExpired:
            return "Setup token has expired. Please request a new setup link."
        case .passwordAlreadySet:
            return "Password has already been set for this account"
        case .passwordNotSet:
            return "Please complete account setup by setting your password first"
        }
    }
}
