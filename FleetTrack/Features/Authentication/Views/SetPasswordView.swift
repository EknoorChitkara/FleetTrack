//
//  SetPasswordView.swift
//  FleetTrack
//
//  View shown when a driver clicks the invite link to set their password
//

import SwiftUI
import Supabase
import UIKit

struct SetPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var message = ""
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer().frame(height: 60)
                
                // Icon
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.appEmerald)
                    .shadow(color: .appEmerald.opacity(0.3), radius: 10)
                
                // Title
                VStack(spacing: 8) {
                    Text("Set Your Password")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Create a secure password for your account")
                        .font(.subheadline)
                        .foregroundColor(.appSecondaryText)
                        .multilineTextAlignment(.center)
                }
                
                // Password Fields
                VStack(spacing: 16) {
                    SecureField("New Password", text: $password)
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appSecondaryText.opacity(0.3), lineWidth: 1)
                        )
                        .accessibilityLabel("New Password")
                        .accessibilityIdentifier("setpassword_new_field")
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appSecondaryText.opacity(0.3), lineWidth: 1)
                        )
                        .accessibilityLabel("Confirm New Password")
                        .accessibilityIdentifier("setpassword_confirm_field")
                }
                .padding(.horizontal)
                
                // Validation Messages
                if !password.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ValidationRow(isValid: password.count >= 8, text: "At least 8 characters")
                        ValidationRow(isValid: password == confirmPassword && !confirmPassword.isEmpty, text: "Passwords match")
                    }
                    .padding(.horizontal)
                }
                
                // Set Password Button
                Button {
                    Task { await setPassword() }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Set Password")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.appEmerald : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(!isFormValid || isLoading)
                .accessibilityLabel("Set Password Button")
                .accessibilityIdentifier("setpassword_submit_button")
                .accessibilityHint(isFormValid ? "Double tap to set your new password" : "Password must be at least 8 characters and match confirm password")
                
                // Message
                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(showSuccess ? .green : .red)
                        .font(.caption)
                        .padding()
                }
                
                Spacer()
            }
        }
    }
    
    private var isFormValid: Bool {
        password.count >= 8 && password == confirmPassword
    }
    
    private func setPassword() async {
        isLoading = true
        message = ""
        
        do {
            // Update the user's password
            try await supabase.auth.update(user: UserAttributes(password: password))
            
            print("✅ Password set successfully")
            
            await MainActor.run {
                showSuccess = true
                message = "✅ Password set successfully! You can now log in."
                isLoading = false
                UIAccessibility.post(notification: .announcement, argument: "Password set successfully. Redirecting to login.")
            }
            
            // Dismiss after a delay
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Sign out so user can log in with new password
            try? await supabase.auth.signOut()
            
            await MainActor.run {
                // Hide the set password view
                AppState.shared.showSetPassword = false
            }
        } catch {
            print("❌ Error setting password: \(error)")
            await MainActor.run {
                message = "Failed to set password: \(error.localizedDescription)"
                isLoading = false
                UIAccessibility.post(notification: .announcement, argument: "Failed to set password: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Validation Row

struct ValidationRow: View {
    let isValid: Bool
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .gray)
                .font(.system(size: 14))
            
            Text(text)
                .foregroundColor(isValid ? .green : .gray)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text): \(isValid ? "Requirement met" : "Requirement not met")")
        .accessibilityIdentifier("setpassword_validation_\(text.replacingOccurrences(of: " ", with: "_").lowercased())")
    }
}

#Preview {
    SetPasswordView()
}
