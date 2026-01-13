//
//  FleetTrackApp.swift
//  FleetTrack
//
//  Created by Eknoor on 07/01/26.
//

import SwiftUI
import Supabase
import Combine

// Global app state for deep link handling
class AppState: ObservableObject {
    static let shared = AppState()
    @Published var showSetPassword = false
    @Published var showResetPassword = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var deepLinkURL: URL?
}

@main
struct FleetTrackApp: App {
    @StateObject private var appState = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                
                // Overlay SetPasswordView when needed
                if appState.showSetPassword {
                    SetPasswordView()
                        .transition(.move(edge: .bottom))
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .fullScreenCover(isPresented: $appState.showResetPassword) {
                if let url = appState.deepLinkURL {
                    ResetPasswordView(url: url)
                }
            }
            .alert("Link Error", isPresented: $appState.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(appState.errorMessage)
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        print("📱 Deep link received: \(url)")
        
        let urlString = url.absoluteString
        
        // Check for errors in the deep link first
        if urlString.contains("error=") {
            print("❌ Deep link contains error")
            
            if urlString.contains("otp_expired") || urlString.contains("invalid") {
                appState.errorMessage = "This link has expired. Please request a new invitation."
                appState.showError = true
            } else if urlString.contains("access_denied") {
                appState.errorMessage = "Access denied. Please contact your administrator."
                appState.showError = true
            } else {
                appState.errorMessage = "An error occurred. Please try again."
                appState.showError = true
            }
            return
        }
        
        // Handle invite/signup links (user setting password for first time)
        if urlString.contains("type=invite") || urlString.contains("type=signup") || urlString.contains("set-password") {
            print("🔐 Invite link detected - establishing session...")
            
            Task {
                do {
                    // Check if URL contains access_token (implicit flow) or code (PKCE flow)
                    if urlString.contains("access_token=") {
                        // Implicit flow - extract tokens from URL fragment
                        print("📍 Implicit flow detected - extracting tokens from URL")
                        
                        // Parse the fragment to get tokens
                        guard let fragment = url.fragment else {
                            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "No fragment in URL"])
                        }
                        
                        // Parse fragment into dictionary
                        var params: [String: String] = [:]
                        for param in fragment.components(separatedBy: "&") {
                            let parts = param.components(separatedBy: "=")
                            if parts.count == 2 {
                                params[parts[0]] = parts[1].removingPercentEncoding ?? parts[1]
                            }
                        }
                        
                        guard let accessToken = params["access_token"],
                              let refreshToken = params["refresh_token"] else {
                            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing tokens in URL"])
                        }
                        
                        print("🔑 Tokens extracted, setting session...")
                        
                        // Set the session with the extracted tokens
                        try await SupabaseClientManager.shared.client.auth.setSession(
                            accessToken: accessToken,
                            refreshToken: refreshToken
                        )
                        print("✅ Session established from invite link (implicit flow)")
                        
                    } else {
                        // PKCE flow - let Supabase handle the URL
                        try await SupabaseClientManager.shared.client.auth.session(from: url)
                        print("✅ Session established from invite link (PKCE flow)")
                    }
                    
                    // Show the set password view
                    await MainActor.run {
                        appState.showSetPassword = true
                    }
                } catch {
                    print("❌ Failed to establish session from invite link: \(error)")
                    await MainActor.run {
                        appState.errorMessage = "Failed to process invite link. Please try again."
                        appState.showError = true
                    }
                }
            }
            
        // Handle password reset links
        } else if urlString.contains("reset-password") || urlString.contains("type=recovery") {
            print("🔐 Password reset link detected")
            
            Task {
                do {
                    try await SupabaseClientManager.shared.client.auth.session(from: url)
                    print("✅ Session established from reset link")
                    
                    await MainActor.run {
                        appState.deepLinkURL = url
                        appState.showResetPassword = true
                    }
                } catch {
                    print("❌ Failed to establish session from reset link: \(error)")
                    await MainActor.run {
                        appState.errorMessage = "Failed to process reset link. It may have expired."
                        appState.showError = true
                    }
                }
            }
            
        // Handle magic link login
        } else if urlString.contains("login-callback") || urlString.contains("type=magiclink") {
            print("✨ Magic link detected")
            
            Task {
                do {
                    try await SupabaseClientManager.shared.client.auth.session(from: url)
                    print("✅ Magic link login successful")
                } catch {
                    print("❌ Magic link login failed: \(error)")
                }
            }
            
        // Handle auth callback (general)
        } else if urlString.contains("auth/callback") {
            print("🔐 Auth callback received")
            Task {
                do {
                    try await SupabaseClientManager.shared.client.auth.session(from: url)
                    print("✅ Auth callback processed")
                } catch {
                    print("❌ Auth callback failed: \(error)")
                }
            }
            
        } else {
            print("❓ Unknown deep link type: \(urlString)")
        }
    }
}

