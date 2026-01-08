//
//  MockDataStore.swift
//  authFMS
//
//  Created by Eknoor on 04/01/26.
//

import Foundation

/// In-memory data store for mocking backend database
class MockDataStore: ObservableObject {
    
    static let shared = MockDataStore()
    
    // MARK: - Storage
    
    @Published private(set) var users: [User] = []
    @Published private(set) var sessions: [UserSession] = []
    @Published private(set) var twoFactorConfigs: [TwoFactorAuth] = []
    @Published private(set) var passwordResetTokens: [String: (userID: UUID, token: String, expiresAt: Date)] = [:]
    @Published private(set) var setupTokens: [SetupToken] = []
    
    private init() {
        loadTestData()
    }
    
    // MARK: - User Operations
    
    /// Find user by email
    func findUser(byEmail email: String) -> User? {
        return users.first { $0.email?.lowercased() == email.lowercased() }
    }
    
    /// Find user by phone number
    func findUser(byPhone phone: String) -> User? {
        let cleanedPhone = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return users.first {
            guard let userPhone = $0.phoneNumber else { return false }
            let cleanedUserPhone = userPhone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            return cleanedUserPhone == cleanedPhone
        }
    }
    
    /// Find user by employee ID
    func findUser(byEmployeeID employeeID: String) -> User? {
        return users.first { $0.employeeID?.uppercased() == employeeID.uppercased() }
    }
    
    /// Find user by ID
    func findUser(byID id: UUID) -> User? {
        return users.first { $0.id == id }
    }
    
    /// Create new user
    func createUser(_ user: User) -> Bool {
        // Check for duplicates
        if let email = user.email, findUser(byEmail: email) != nil {
            return false
        }
        if let phone = user.phoneNumber, findUser(byPhone: phone) != nil {
            return false
        }
        if let employeeID = user.employeeID, findUser(byEmployeeID: employeeID) != nil {
            return false
        }
        
        users.append(user)
        return true
    }
    
    /// Update user
    func updateUser(_ user: User) {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
        }
    }
    
    /// Delete user
    func deleteUser(byID id: UUID) {
        users.removeAll { $0.id == id }
        sessions.removeAll { $0.userID == id }
        twoFactorConfigs.removeAll { $0.userID == id }
    }
    
    // MARK: - Session Operations
    
    /// Find session by token
    func findSession(byToken token: String) -> UserSession? {
        return sessions.first { $0.token == token }
    }
    
    /// Find sessions for user
    func findSessions(forUserID userID: UUID) -> [UserSession] {
        return sessions.filter { $0.userID == userID }
    }
    
    /// Create session
    func createSession(_ session: UserSession) {
        sessions.append(session)
    }
    
    /// Update session
    func updateSession(_ session: UserSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        }
    }
    
    /// Delete session
    func deleteSession(byToken token: String) {
        sessions.removeAll { $0.token == token }
    }
    
    /// Delete all sessions for user
    func deleteAllSessions(forUserID userID: UUID) {
        sessions.removeAll { $0.userID == userID }
    }
    
    /// Clean up expired sessions
    func cleanupExpiredSessions() {
        sessions.removeAll { $0.isExpired }
    }
    
    // MARK: - 2FA Operations
    
    /// Find 2FA config for user
    func find2FAConfig(forUserID userID: UUID) -> TwoFactorAuth? {
        return twoFactorConfigs.first { $0.userID == userID }
    }
    
    /// Create 2FA config
    func create2FAConfig(_ config: TwoFactorAuth) {
        twoFactorConfigs.append(config)
    }
    
    /// Update 2FA config
    func update2FAConfig(_ config: TwoFactorAuth) {
        if let index = twoFactorConfigs.firstIndex(where: { $0.id == config.id }) {
            twoFactorConfigs[index] = config
        }
    }
    
    /// Delete 2FA config
    func delete2FAConfig(forUserID userID: UUID) {
        twoFactorConfigs.removeAll { $0.userID == userID }
    }
    
    // MARK: - Password Reset Operations
    
    /// Create password reset token
    func createPasswordResetToken(forUserID userID: UUID) -> String {
        let token = CryptoHelpers.generatePasswordResetToken()
        let expiresAt = Date().addingTimeInterval(3600) // 1 hour
        passwordResetTokens[token] = (userID: userID, token: token, expiresAt: expiresAt)
        return token
    }
    
    /// Validate password reset token
    func validatePasswordResetToken(_ token: String) -> UUID? {
        guard let resetInfo = passwordResetTokens[token],
              Date() < resetInfo.expiresAt else {
            return nil
        }
        return resetInfo.userID
    }
    
    /// Use password reset token (invalidates it)
    func usePasswordResetToken(_ token: String) {
        passwordResetTokens.removeValue(forKey: token)
    }
    
    // MARK: - Setup Token Operations
    
    /// Create setup token for account password setup
    func createSetupToken(forUserID userID: UUID) -> String {
        let setupToken = SetupToken.create(for: userID)
        setupTokens.append(setupToken)
        return setupToken.token
    }
    
    /// Validate setup token
    func validateSetupToken(_ token: String) -> UUID? {
        guard let setupToken = setupTokens.first(where: { $0.token == token }),
              setupToken.isValid else {
            return nil
        }
        return setupToken.userID
    }
    
    /// Mark setup token as used (invalidates it)
    func useSetupToken(_ token: String) {
        if let index = setupTokens.firstIndex(where: { $0.token == token }) {
            setupTokens[index].markAsUsed()
        }
    }
    
    /// Cleanup expired setup tokens
    func cleanupExpiredSetupTokens() {
        setupTokens.removeAll { $0.isExpired || $0.isUsed }
    }
    
    // MARK: - Test Data
    
    /// Load pre-populated test data
    private func loadTestData() {
        // NOTE: Admin accounts are no longer pre-created
        // They must be created via createAdminAccount() flow
        
        // Create test driver
        let driverPasswordHash = CryptoHelpers.hashPassword("Driver@123")
        let driver = User(
            role: .driver,
            phoneNumber: "+15551234567",
            employeeID: "DRV001",
            passwordHash: driverPasswordHash,
            isVerified: true,
            twoFactorEnabled: true
        )
        users.append(driver)
        
        // Create driver 2FA config
        let driverSMS = TwoFactorAuth.createSMS(for: driver.id)
        var enabledDriverSMS = driverSMS
        enabledDriverSMS.isEnabled = true
        twoFactorConfigs.append(enabledDriverSMS)
        
        // Create test maintenance manager
        let maintenancePasswordHash = CryptoHelpers.hashPassword("Maint@123")
        let maintenance = User(
            role: .maintenanceManager,
            employeeID: "MNT001",
            passwordHash: maintenancePasswordHash,
            isVerified: true,
            twoFactorEnabled: true
        )
        users.append(maintenance)
        
        // Create maintenance 2FA config
        let maintenanceTOTP = TwoFactorAuth.createTOTP(for: maintenance.id)
        var enabledMaintenanceTOTP = maintenanceTOTP
        enabledMaintenanceTOTP.isEnabled = true
        twoFactorConfigs.append(enabledMaintenanceTOTP)
        
        print("✅ MockDataStore initialized with test accounts:")
        print("   Driver: +15551234567 + DRV001 / Driver@123")
        print("   Maintenance: MNT001 / Maint@123")
        print("   Note: Admin accounts must be created via createAdminAccount()")
    }
    
    /// Reset to initial state
    func reset() {
        users.removeAll()
        sessions.removeAll()
        twoFactorConfigs.removeAll()
        passwordResetTokens.removeAll()
        setupTokens.removeAll()
        loadTestData()
    }
}
