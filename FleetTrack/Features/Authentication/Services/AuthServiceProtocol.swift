//
//  AuthServiceProtocol.swift
//  FleetTrack
//
//  Created by Architecture Refactor
//

import Foundation

/// Protocol defining the contract for Authentication Services
/// Allows switching between Mock and Real implementations
protocol AuthServiceProtocol {
    
    // MARK: - Admin
    
    /// Create admin account
    func createAdminAccount(email: String) async throws -> (user: User, setupToken: String)
    
    /// Login admin
    func adminLogin(email: String, password: String) async throws -> User
    
    // MARK: - Driver
    
    /// Create driver account
    func createDriverAccount(phoneNumber: String, employeeID: String) async throws -> User
    
    /// Send SMS code for driver login
    func sendDriverSMSCode(phoneNumber: String) async throws -> String
    
    /// Verify SMS code and login driver
    func verifyDriverSMSCode(verificationID: String, code: String, employeeID: String) async throws -> User
    
    /// Verify driver credentials (first step before SMS)
    /// Note: In Firebase, we might skip this or just check existence, 
    /// but to satisfy ViewModel flow we keep it.
    func driverLogin(phoneNumber: String, employeeID: String) async throws -> User
    
    // MARK: - Maintenance Manager
    
    /// Create maintenance account
    func createMaintenanceAccount(employeeID: String, email: String, password: String) async throws -> User
    
    /// Login maintenance manager
    func maintenanceLogin(employeeID: String, password: String) async throws -> User
    
    // MARK: - Session
    
    /// Get currently authenticated user
    func getCurrentUser() async throws -> User?
    
    /// Logout
    func logout() async throws
    
    // MARK: - Password Management
    
    /// Request password reset
    func requestPasswordReset(email: String) async throws -> String
    
    // MARK: - Two Factor (Legacy/Adapter)
    // These might be no-ops or specific to the implementation
    /// Update user profile
    func updateUserProfile(id: UUID, name: String, email: String, phoneNumber: String?) async throws -> User
}
