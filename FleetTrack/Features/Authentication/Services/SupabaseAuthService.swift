//
//  SupabaseAuthService.swift
//  FleetTrack
//
//  Created by Supabase Integration
//

import Foundation
import Supabase

// Access User from Core
// import FleetTrack // explicit if needed, but usually available in same module

class SupabaseAuthService: AuthServiceProtocol {
    
    static let shared = SupabaseAuthService()
    
    // Use the global supabase client from SupabaseClient.swift
    private let client = supabase

    
    private init() {}
    
    /// Expose auth state changes for SessionManager
    var authStateChanges: AsyncStream<(event: AuthChangeEvent, session: Session?)> {
        client.auth.authStateChanges
    }
    
    // MARK: - Admin
    
    func createAdminAccount(email: String) async throws -> (user: User, setupToken: String) {
        // Implement Supabase auth sign up
        // This is a placeholder implementation
        throw SupabaseError.notImplemented
    }
    
    func adminLogin(email: String, password: String) async throws -> User {
        let session = try await client.auth.signIn(email: email, password: password)
        return try await fetchUser(id: session.user.id)
    }
    
    // MARK: - Driver
    
    func createDriverAccount(phoneNumber: String, employeeID: String) async throws -> User {
        throw SupabaseError.notImplemented
    }
    
    func sendDriverSMSCode(phoneNumber: String) async throws -> String {
        try await client.auth.signInWithOTP(phone: phoneNumber)
        return "dummy_verification_id"
    }
    
    func verifyDriverSMSCode(verificationID: String, code: String, employeeID: String) async throws -> User {
        // Note: verifyOTP usually takes phone + code or email + code
        // We might need to store the phone number temporarily or pass it in
        throw SupabaseError.notImplemented
    }
    
    func driverLogin(phoneNumber: String, employeeID: String) async throws -> User {
        // Check existence logic if needed
       throw SupabaseError.notImplemented
    }
    
    // MARK: - Maintenance Manager
    
    func createMaintenanceAccount(employeeID: String, email: String, password: String) async throws -> User {
        throw SupabaseError.notImplemented
    }
    
    func maintenanceLogin(employeeID: String, password: String) async throws -> User {
        let email = "\(employeeID)@fleettrack.com" // Placeholder logic
        let session = try await client.auth.signIn(email: email, password: password)
        return try await fetchUser(id: session.user.id)
    }
    
    // MARK: - Session
    
    func getCurrentUser() async throws -> User? {
        guard let user = try? await client.auth.session.user else {
            return nil
        }
        return try? await fetchUser(id: user.id)
    }
    
    func logout() async throws {
        try await client.auth.signOut()
    }
    
    // MARK: - Password Management
    
    func requestPasswordReset(email: String) async throws -> String {
        try await client.auth.resetPasswordForEmail(email)
        return "password_reset_email_sent"
    }
    
    // MARK: - Two Factor
    
    func verifyTwoFactorCode(userID: UUID, code: String) async throws -> Bool {
        // Implement Supabase MFA verify if applicable
        return true
    }
    
    // MARK: - Helpers
    
    private func fetchUser(id: UUID) async throws -> User {
        // Fetch user profile from 'public.users' table
        let user: User = try await client
            .from("users")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        
        return user
    }
}

enum SupabaseError: Error {
    case notImplemented
}
