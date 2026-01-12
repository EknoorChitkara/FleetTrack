//
//  SessionManager.swift
//  FleetTrack
//
//  Created by Architecture Refactor
//

import Foundation
import Combine

/// Session manager that observes Supabase Auth state
/// Maintains the current User (metadata from Supabase/Database)
class SessionManager: ObservableObject {
    
    static let shared = SessionManager()
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated: Bool = false
    
    private let authService = SupabaseAuthService.shared
    
    private init() {
        startSessionMonitoring()
    }
    
    /// Start checking session
    private func startSessionMonitoring() {
        Task { @MainActor in
            do {
                if let user = try await authService.getCurrentUser() {
                    self.currentUser = user
                    self.isAuthenticated = true
                    print("✅ Session active for: \(user.name)") // Assuming name is available in Core.User
                } else {
                    self.currentUser = nil
                    self.isAuthenticated = false
                    print("🔄 No active session")
                }
            } catch {
                print("⚠️ Session check failed: \(error.localizedDescription)")
                self.currentUser = nil
                self.isAuthenticated = false
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Explicitly set user (called by AuthViewModel after successful login to ensure immediate UI update)
    func setUser(_ user: User) {
        self.currentUser = user
        self.isAuthenticated = true
    }
    
    /// Clear session locally
    func clearSession() {
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
