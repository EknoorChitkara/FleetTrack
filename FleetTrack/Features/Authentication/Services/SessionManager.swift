//
//  SessionManager.swift
//  FleetTrack
//
//  Created by Architecture Refactor
//

import Foundation
import Combine
import Supabase

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
    
    /// Start monitoring Supabase auth state changes
    private func startSessionMonitoring() {
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                await MainActor.run {
                    handleAuthStateChange(event: event, session: session)
                }
            }
        }
    }
    
    @MainActor
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) {
        print("🔔 Auth State Change: \(event)")
        
        switch event {
        case .signedIn, .initialSession, .tokenRefreshed:
            if let session = session {
                Task {
                    do {
                        let user = try await authService.getCurrentUser()
                        await MainActor.run {
                            self.currentUser = user
                            self.isAuthenticated = true
                        }
                    } catch {
                        print("⚠️ Failed to fetch user profile: \(error.localizedDescription)")
                        await MainActor.run {
                            self.isAuthenticated = false
                            self.currentUser = nil
                        }
                    }
                }
            }
        case .signedOut:
            self.currentUser = nil
            self.isAuthenticated = false
            print("🔄 User signed out")
        default:
            break
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
