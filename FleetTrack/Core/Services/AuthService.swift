//
//  AuthService.swift
//  FleetTrack
//
//  Created by FleetTrack on 08/01/26.
//

import Foundation
import Supabase
import Combine

/// Authentication service handling all Supabase auth operations
@MainActor
final class AuthService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AuthService()
    
    // MARK: - Published Properties
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private var client: SupabaseClient {
        SupabaseClientManager.shared.client
    }
    
    // MARK: - Initialization
    
    nonisolated private init() {
        print("✅ AuthService initialized")
    }
    
    // MARK: - Session Management
    
    /// Check if there's an existing valid session
    func checkSession() async {
        do {
            let session = try await client.auth.session
            print("✅ Found existing session for user: \(session.user.email ?? "unknown")")
            await fetchUserProfile(userId: session.user.id)
        } catch {
            print("ℹ️ No existing session: \(error.localizedDescription)")
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    // MARK: - Sign Up
    
    /// Register a new user with email and password
    func signUp(email: String, password: String, name: String, phoneNumber: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // Create auth user
            let authResponse = try await client.auth.signUp(
                email: email,
                password: password
            )
            
            let userId = authResponse.user.id
            
            // Create user profile in users table
            let userProfile = UserProfile(
                id: userId,
                name: name,
                email: email,
                phoneNumber: phoneNumber,
                role: "Driver", // Default role - admin can change in Supabase
                isActive: true,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await client
                .from(SupabaseConfig.usersTable)
                .insert(userProfile)
                .execute()
            
            print("✅ Sign up successful for: \(email)")
            
            // Fetch the full user profile
            await fetchUserProfile(userId: userId)
            
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            throw error
        } catch {
            errorMessage = error.localizedDescription
            throw AuthError.signUpFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Sign In
    
    /// Sign in with email and password
    @discardableResult
    func signIn(email: String, password: String) async throws -> UserRole {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            // Fetch user profile to get role
            await fetchUserProfile(userId: session.user.id)
            
            guard let user = currentUser else {
                throw AuthError.profileNotFound
            }
            
            // 🎯 PRINT THE USER ROLE ON LOGIN
            print("═══════════════════════════════════════════")
            print("🔐 LOGIN SUCCESSFUL")
            print("📧 Email: \(user.email)")
            print("👤 Name: \(user.name)")
            print("🎭 ROLE: \(user.role.rawValue)")
            print("═══════════════════════════════════════════")
            
            return user.role
            
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            throw error
        } catch {
            errorMessage = error.localizedDescription
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Sign Out
    
    /// Sign out the current user
    func signOut() async throws {
        isLoading = true
        
        defer { isLoading = false }
        
        do {
            try await client.auth.signOut()
            currentUser = nil
            isAuthenticated = false
            print("✅ Sign out successful")
        } catch {
            errorMessage = error.localizedDescription
            throw AuthError.signOutFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Password Reset
    
    /// Send password reset email
    /// Uses redirectTo URL to bring user back to app
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // Send reset email with redirect to app callback URL
            try await client.auth.resetPasswordForEmail(
                email,
                redirectTo: SupabaseConfig.redirectURL
            )
            print("✅ Password reset email sent to: \(email)")
            print("📧 Redirect URL: \(SupabaseConfig.redirectURL)")
        } catch {
            errorMessage = error.localizedDescription
            throw AuthError.resetPasswordFailed(error.localizedDescription)
        }
    }
    
    /// Update password after receiving reset link
    func updatePassword(newPassword: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await client.auth.update(user: .init(password: newPassword))
            print("✅ Password updated successfully")
        } catch {
            errorMessage = error.localizedDescription
            throw AuthError.updatePasswordFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Handle Deep Link (Password Recovery)
    
    /// Handle incoming deep link URL for password reset
    /// Supabase sends: fleettrack://auth/callback#type=recovery&access_token=XYZ
    /// - Returns: true if this is a recovery link and session was established
    func handleDeepLink(url: URL) async -> Bool {
        print("🔗 Handling deep link: \(url.absoluteString)")
        
        // Check if this is our auth callback
        guard url.scheme == SupabaseConfig.urlScheme,
              url.host == "auth",
              url.path == "/callback" || url.path.contains("callback") else {
            print("ℹ️ Not an auth callback URL")
            return false
        }
        
        // Parse URL fragment (Supabase uses fragment, not query)
        guard let fragment = url.fragment else {
            print("ℹ️ No fragment in URL")
            return false
        }
        
        // Parse fragment into dictionary
        let params = fragment
            .split(separator: "&")
            .reduce(into: [String: String]()) { dict, pair in
                let parts = pair.split(separator: "=")
                if parts.count == 2 {
                    dict[String(parts[0])] = String(parts[1])
                }
            }
        
        print("📋 Parsed params: \(params)")
        
        // Check if this is a password recovery link
        if params["type"] == "recovery" {
            print("✅ Password recovery deep link detected")
            
            // Try to set session from tokens in the URL fragment
            if let accessToken = params["access_token"],
               let refreshToken = params["refresh_token"] {
                do {
                    try await client.auth.setSession(accessToken: accessToken, refreshToken: refreshToken)
                    print("✅ Session set from recovery tokens")
                    return true
                } catch {
                    print("❌ Failed to set session: \(error.localizedDescription)")
                    return false
                }
            } else {
                print("⚠️ No tokens found in recovery URL")
                return false
            }
        }
        
        return false
    }
    
    // MARK: - Private Methods
    
    /// Fetch user profile from database
    private func fetchUserProfile(userId: UUID) async {
        do {
            let profile: UserProfile = try await client
                .from(SupabaseConfig.usersTable)
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            // Convert to User model
            self.currentUser = User(
                id: profile.id,
                name: profile.name,
                email: profile.email,
                phoneNumber: profile.phoneNumber,
                role: UserRole(rawValue: profile.role) ?? .driver,
                profileImageURL: profile.profileImageURL,
                isActive: profile.isActive,
                createdAt: profile.createdAt,
                updatedAt: profile.updatedAt
            )
            self.isAuthenticated = true
            print("✅ User profile loaded: \(profile.name)")
            
        } catch {
            print("❌ Failed to fetch user profile: \(error.localizedDescription)")
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
}

// MARK: - User Profile (Database Model)

struct UserProfile: Codable {
    let id: UUID
    let name: String
    let email: String
    let phoneNumber: String
    let role: String
    var profileImageURL: String?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phoneNumber = "phone_number"
        case role
        case profileImageURL = "profile_image_url"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case signUpFailed(String)
    case signInFailed(String)
    case signOutFailed(String)
    case resetPasswordFailed(String)
    case updatePasswordFailed(String)
    case profileNotFound
    case invalidSession
    
    var errorDescription: String? {
        switch self {
        case .signUpFailed(let message):
            return "Sign up failed: \(message)"
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .signOutFailed(let message):
            return "Sign out failed: \(message)"
        case .resetPasswordFailed(let message):
            return "Password reset failed: \(message)"
        case .updatePasswordFailed(let message):
            return "Password update failed: \(message)"
        case .profileNotFound:
            return "User profile not found"
        case .invalidSession:
            return "Invalid session"
        }
    }
}
