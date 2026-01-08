//
//  FirebaseAuthService.swift
//  FleetTrack
//
//  Created by Architecture Refactor
//

import Foundation

/// Production Authentication Service using Firebase
class FirebaseAuthService: AuthServiceProtocol {
    
    static let shared = FirebaseAuthService()
    
    private let adapter = FirebaseAuthAdapter.shared
    
    // State to bridge between VM flow and Firebase requirements
    private var tempVerificationID: String?
    
    private init() {}
    
    // MARK: - Admin
    
    func createAdminAccount(email: String) async throws -> (user: User, setupToken: String) {
        let result = try await adapter.createAdminAccount(email: email)
        // Adapter returns (User, String) where String is setupToken
        return result
    }
    
    func adminLogin(email: String, password: String) async throws -> User {
        return try await adapter.adminLogin(email: email, password: password)
    }
    
    // MARK: - Driver
    
    func createDriverAccount(phoneNumber: String, employeeID: String) async throws -> User {
        return try await adapter.createDriverAccount(phoneNumber: phoneNumber, employeeID: employeeID)
    }
    
    func driverLogin(phoneNumber: String, employeeID: String) async throws -> User {
        // 1. Fetch user to validate existence and credentials (locally)
        // This bridges the VM expectation of getting a User object before SMS
        let user = try await adapter.fetchUserMetadataByPhone(phoneNumber: phoneNumber)
        
        // 2. Validate Employee ID
        guard user.employeeID?.uppercased() == employeeID.uppercased() else {
            throw FirebaseAuthError.invalidCredentials
        }
        
        return user
    }
    
    func sendDriverSMSCode(phoneNumber: String) async throws -> String {
        let vid = try await adapter.sendDriverSMSCode(phoneNumber: phoneNumber)
        self.tempVerificationID = vid
        return vid
    }
    
    func verifyDriverSMSCode(verificationID: String, code: String, employeeID: String) async throws -> User {
        return try await adapter.verifyDriverSMSCode(
            verificationID: verificationID,
            code: code,
            employeeID: employeeID
        )
    }
    
    // MARK: - Maintenance
    
    func createMaintenanceAccount(employeeID: String, email: String, password: String) async throws -> User {
        return try await adapter.createMaintenanceAccount(
            employeeID: employeeID,
            email: email,
            password: password
        )
    }
    
    func maintenanceLogin(employeeID: String, password: String) async throws -> User {
        return try await adapter.maintenanceLogin(
            employeeID: employeeID,
            password: password
        )
    }
    
    // MARK: - Session
    
    func getCurrentUser() async throws -> User? {
        return try await adapter.getCurrentUser()
    }
    
    func logout() async throws {
        try adapter.logout()
        tempVerificationID = nil
    }
    
    // MARK: - Password & 2FA
    
    func requestPasswordReset(email: String) async throws -> String {
        try await adapter.sendPasswordResetEmail(email: email)
        return "firebase_reset_sent"
    }
    
    /// Adapt legacy 2FA verification from VM
    func verifyTwoFactorCode(userID: UUID, code: String) async throws -> Bool {
        // For Drivers (SMS Flow)
        if tempVerificationID != nil {
            throw FirebaseAuthError.invalidCredentials // Force specific flow
        }
        
        return false
    }
    
    // Specific method for VM to call ensuring we use the stored ID
    func verifyTwoFactorCodeForDriver(employeeID: String, code: String) async throws -> User {
        guard let vid = tempVerificationID else {
            throw FirebaseAuthError.invalidCredentials
        }
        
        return try await adapter.verifyDriverSMSCode(
            verificationID: vid,
            code: code,
            employeeID: employeeID
        )
    }
}
