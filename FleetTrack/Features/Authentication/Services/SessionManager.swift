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
    @Published var isLoading: Bool = true // Added to track initial check
    
    private let authService = SupabaseAuthService.shared
    
    private init() {
        startSessionMonitoring()
    }
    
    /// Start checking session and listen for changes
    private func startSessionMonitoring() {
        Task { @MainActor in
            self.isLoading = true
            
            // Bypass logic for development
            if DevelopmentConfig.bypassLogin {
                print("⚠️ DEVELOPMENT BYPASS ENABLED: Logging in as \(DevelopmentConfig.defaultRole)")
                self.currentUser = DevelopmentConfig.mockUser
                self.isAuthenticated = true
                self.isLoading = false
                return
            }
            
            // 1. Initial Check
            await checkCurrentSession()
            
            // 2. Listen for Auth Changes (Deep Links, Sign Outs, etc.)
            for await _ in authService.authStateChanges {
                await checkCurrentSession()
            }
        }
    }
    
    @MainActor
    private func checkCurrentSession() async {
        do {
            if let user = try await authService.getCurrentUser() {
                self.currentUser = user
                self.isAuthenticated = true
                print("✅ Session active for: \(user.name)")
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
        self.isLoading = false
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
