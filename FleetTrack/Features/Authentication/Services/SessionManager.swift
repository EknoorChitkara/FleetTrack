//
//  SessionManager.swift
//  authFMS
//
//  Created by Eknoor on 04/01/26.
//

import Foundation
import Combine

/// Session manager for handling user authentication state
class SessionManager: ObservableObject {
    
    static let shared = SessionManager()
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentSession: UserSession?
    
    private let authService = MockAuthService.shared
    private let keychain = KeychainHelper.shared
    private let dataStore = MockDataStore.shared
    
    private var sessionCheckTimer: Timer?
    
    private init() {
        restoreSession()
        startSessionMonitoring()
    }
    
    // MARK: - Session Restoration
    
    /// Restore session from keychain on app launch
    private func restoreSession() {
        guard let token = keychain.retrieveString(forKey: KeychainHelper.Keys.sessionToken),
              let userIDString = keychain.retrieveString(forKey: KeychainHelper.Keys.currentUserID),
              let userID = UUID(uuidString: userIDString) else {
            print("ℹ️ No saved session found")
            return
        }
        
        // Validate session
        Task {
            do {
                let user = try await authService.validateSession(token: token)
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                    if let session = dataStore.findSession(byToken: token) {
                        self.currentSession = session
                    }
                    print("✅ Session restored for: \(user.displayName)")
                }
            } catch {
                print("❌ Session restoration failed: \(error.localizedDescription)")
                await MainActor.run {
                    clearSession()
                }
            }
        }
    }
    
    // MARK: - Login
    
    /// Set authenticated user and session
    func setSession(user: User, session: UserSession) {
        self.currentUser = user
        self.currentSession = session
        self.isAuthenticated = true
        
        // Save to keychain
        keychain.save(session.token, forKey: KeychainHelper.Keys.sessionToken)
        keychain.save(user.id.uuidString, forKey: KeychainHelper.Keys.currentUserID)
        
        print("✅ Session established for: \(user.displayName)")
    }
    
    // MARK: - Logout
    
    /// Logout current user
    func logout() async {
        guard let token = currentSession?.token else {
            clearSession()
            return
        }
        
        do {
            try await authService.logout(token: token)
        } catch {
            print("⚠️ Logout error: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            clearSession()
        }
    }
    
    /// Logout from all devices
    func logoutAllDevices() async {
        guard let userID = currentUser?.id else { return }
        
        do {
            try await authService.logoutAllDevices(userID: userID)
        } catch {
            print("⚠️ Logout all devices error: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            clearSession()
        }
    }
    
    /// Clear local session
    private func clearSession() {
        currentUser = nil
        currentSession = nil
        isAuthenticated = false
        
        // Clear keychain
        keychain.delete(forKey: KeychainHelper.Keys.sessionToken)
        keychain.delete(forKey: KeychainHelper.Keys.currentUserID)
        
        print("✅ Session cleared")
    }
    
    // MARK: - Session Monitoring
    
    /// Start monitoring session expiration
    private func startSessionMonitoring() {
        sessionCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkSessionValidity()
        }
    }
    
    /// Check if current session is still valid
    private func checkSessionValidity() {
        guard let session = currentSession else { return }
        
        if session.isExpired {
            print("⚠️ Session expired")
            Task {
                await MainActor.run {
                    clearSession()
                }
            }
        }
    }
    
    // MARK: - Session Info
    
    /// Get time remaining in current session
    var sessionTimeRemaining: String? {
        return currentSession?.timeRemainingFormatted
    }
    
    /// Check if session is about to expire (less than 1 hour)
    var sessionExpiringSoon: Bool {
        guard let session = currentSession else { return false }
        return session.timeRemaining < 3600 && session.timeRemaining > 0
    }
    
    deinit {
        sessionCheckTimer?.invalidate()
    }
}
