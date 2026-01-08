//
//  SessionManager.swift
//  FleetTrack
//
//  Created by Architecture Refactor
//

import Foundation
import Combine
import FirebaseAuth

/// Session manager that observes Firebase Auth state
/// Maintains the current User (metadata from Firestore)
class SessionManager: ObservableObject {
    
    static let shared = SessionManager()
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated: Bool = false
    
    private let adapter = FirebaseAuthAdapter.shared
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        startSessionMonitoring()
    }
    
    /// Start listening to Firebase Auth changes
    private func startSessionMonitoring() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let firebaseUser = firebaseUser {
                    print("🔄 Firebase Auth State: Logged In (\(firebaseUser.uid))")
                    do {
                        // Fetch full user profile from Firestore
                        // We use the adapter's method which determines if it uses cache or network
                        if let user = try? await self.adapter.getCurrentUser() {
                            self.currentUser = user
                            self.isAuthenticated = true
                            print("✅ Session active for: \(user.displayName)")
                        } else {
                            // Valid Firebase User but no Firestore document?
                            // This might happen during creation before doc is written.
                            // We wait or let the explicit flow handle it.
                            print("⚠️ Firebase User exists but Firestore metadata not found yet.")
                        }
                    }
                } else {
                    print("🔄 Firebase Auth State: Logged Out")
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
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
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
}
