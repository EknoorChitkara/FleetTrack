//
//  ResetPasswordView.swift
//  FleetTrack
//
//  Created by Eknoor on 07/01/26.
//

import SwiftUI
import Supabase

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL?
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var message = ""
    @State private var isLoading = false
    @State private var isSessionSet = false
    
    // Detect if this is an invite (new user) or recovery (password reset)
    private var isInvite: Bool {
        guard let url = url else { return false }
        let fragment = url.fragment?.lowercased() ?? ""
        
        // If the URL explicitly contains "recovery", it's a Reset Password flow
        if fragment.contains("recovery") {
            return false
        }
        
        // Otherwise, if it's an auth callback, we treat it as an Invite/Setup flow
        return true
    }
    
    private var titleText: String {
        isInvite ? "Set Your Password" : "Reset Password"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)
                    
                    Image(systemName: isInvite ? "person.badge.key.fill" : "key.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.appEmerald)
                        .shadow(color: .appEmerald.opacity(0.3), radius: 10)
                    
                    VStack(spacing: 8) {
                        Text(titleText)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if isInvite {
                            Text("Welcome! Please set your password to get started.")
                                .font(.subheadline)
                                .foregroundColor(.appSecondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    Spacer().frame(height: 20)
                    
                    if !isSessionSet {
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.appEmerald)
                            Text("Securing your connection...")
                                .foregroundColor(.appSecondaryText)
                                .font(.caption)
                        }
                        .task { await setupSession() }
                    } else {
                        VStack(spacing: 16) {
                            SecureField("", text: $newPassword, prompt: Text("New Password").foregroundColor(.appSecondaryText))
                                .padding()
                                .background(Color.appCardBackground)
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appSecondaryText.opacity(0.3), lineWidth: 1))
                            
                            SecureField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundColor(.appSecondaryText))
                                .padding()
                                .background(Color.appCardBackground)
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appSecondaryText.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.horizontal)
                        
                        Button { Task { await updatePassword() } } label: {
                            HStack {
                                if isLoading { 
                                    ProgressView().tint(.white) 
                                } else { 
                                    Text(isInvite ? "Set Password" : "Update Password")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(gradient: Gradient(colors: [.appEmerald, .appEmerald.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .appEmerald.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                        .disabled(isLoading || message.contains("expired"))
                    }
                    
                    if !message.isEmpty {
                        Text(message)
                            .foregroundColor(message.contains("✅") ? .appEmeraldLight : .red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("")
            .toolbar { 
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appEmerald)
                }
            }
        }
    }
    
    private func setupSession() async {
        guard let url = url else {
            print("⚠️ No URL provided to ResetPasswordView")
            isSessionSet = true
            return
        }
        
        print("🔗 Processing link: \(url.absoluteString)")
        
        // 1. Try to extract tokens from fragment OR query (Supabase can send both)
        var params: [String: String] = [:]
        
        // Parse Fragment
        if let fragment = url.fragment {
            fragment.split(separator: "&").forEach { pair in
                let parts = pair.split(separator: "=")
                if parts.count == 2 { params[String(parts[0])] = String(parts[1]) }
            }
        }
        
        // Parse Query (Fallback)
        if params.isEmpty, let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let items = components.queryItems {
            for item in items { params[item.name] = item.value }
        }
        
        if let error = params["error_description"] {
            message = "❌ \(error.replacingOccurrences(of: "+", with: " "))\n\nPlease request a new invite."
            isSessionSet = true
            return
        }
        
        if let accessToken = params["access_token"], let refreshToken = params["refresh_token"] {
            do {
                try await supabase.auth.setSession(accessToken: accessToken, refreshToken: refreshToken)
                print("✅ Session active! User: \(try? await supabase.auth.session.user.email ?? "unknown")")
                isSessionSet = true
                return
            } catch {
                print("❌ Manual Session Error: \(error)")
            }
        }
        
        // 2. Fallback to helper
        do {
            try await supabase.auth.session(from: url)
            print("✅ Helper Session Success")
            isSessionSet = true
        } catch {
            print("❌ All session attempts failed: \(error)")
            message = "❌ Session failed. Link might be expired or used."
            isSessionSet = true
        }
    }
    
    private func updatePassword() async {
        guard newPassword == confirmPassword else { message = "❌ Passwords do not match"; return }
        
        let currentSession = try? await supabase.auth.session
        print("👤 Current session before update: \(currentSession?.user.email ?? "NIL")")
        
        isLoading = true
        do {
            try await supabase.auth.update(user: UserAttributes(password: newPassword))
            message = "✅ Updated!"; try? await Task.sleep(for: .seconds(1))
            dismiss()
        } catch {
            message = "❌ \(error.localizedDescription)"
        }
        isLoading = false
    }
}

