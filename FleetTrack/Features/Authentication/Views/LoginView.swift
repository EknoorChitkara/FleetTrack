//
//  LoginView.swift
//  FleetTrack
//
//  Created by Firebase Integration
//

import SwiftUI

/// Placeholder Login View
/// This will be implemented in Phase 3
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("FleetTrack Login")
                .font(.largeTitle)
                .bold()
            
            Text("Authentication System Active")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Logout button (for testing)
            if authViewModel.isAuthenticated {
                Button("Logout Current Session") {
                    Task {
                        await authViewModel.logout()
                    }
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            
            // Temporary Debug Login Buttons
            VStack(spacing: 12) {
                Button("Create Test Admin") {
                    Task {
                        do {
                            // ⚠️ SECURITY: Never commit real emails to Git
                            // Replace this with your email when testing locally
                            let testEmail = "eknoor1655.be23@chitkara.edu.in"// TODO: Replace locally for testing
                            
                            // Direct call to adapter for seeding
                            let (user, tempPassword) = try await FirebaseAuthAdapter.shared.createAdminAccount(email: testEmail)
                            
                            print("✅ Test Admin Created")
                            print("📧 Email: \(testEmail)")
                            print("🔑 Temporary Password: \(tempPassword)")
                            print("📬 Password reset email sent to your inbox!")
                            print("⚠️ Check your email and click the reset link to set your password")
                            
                            // Show alert to user
                            authViewModel.errorMessage = "Admin created! Check \(testEmail) for password reset email."
                            authViewModel.showError = true
                        } catch {
                            print("❌ Error: \(error.localizedDescription)")
                            authViewModel.errorMessage = error.localizedDescription
                            authViewModel.showError = true
                        }
                    }
                }
                .buttonStyle(.bordered)
                .tint(.green)
                
                Button("Login as Admin") {
                    Task {
                        // ⚠️ SECURITY: Never commit real passwords to Git
                        // Replace these when testing locally
                        await authViewModel.adminLogin(
                            email: "admin@example.com", // TODO: Replace locally
                            password: "YourPasswordHere" // TODO: Replace locally
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            if authViewModel.isLoading {
                ProgressView()
            }
            
            if let error = authViewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }
}
