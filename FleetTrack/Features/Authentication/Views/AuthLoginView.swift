//
//  LoginView.swift
//  FleetTrack
//
//  Created by Supabase Integration
//

import SwiftUI

/// Placeholder Login View
/// This will be implemented in Phase 3
struct AuthLoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("FleetTrack Login")
                .font(.largeTitle)
                .bold()
            
            Text("Supabase Auth System Active")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Logout button (for testing)
//            if authViewModel.isAuthenticated {
//                Button("Logout Current Session") {
//                    Task {
//                        await authViewModel.logout()
//                    }
//                }
//                .buttonStyle(.bordered)
//                .tint(.red)
//            }
////            
            // Temporary Debug Login Buttons
            VStack(spacing: 12) {
                Button("Create Test Admin (Mock)") {
                    Task {
                        do {
                            // ⚠️ SECURITY: Never commit real emails to Git
                            let testEmail = "admin@example.com"
                            
                            // Direct call to service for seeding (using shared instance cast or protocol if method exists)
                            // Since createAdminAccount is in protocol, we can use accessing via viewModel or instance
                            let (user, tempPassword) = try await SupabaseAuthService.shared.createAdminAccount(email: testEmail)
                            
                            print("✅ Test Admin Created")
                            print("📧 Email: \(testEmail)")
                            print("🔑 Setup Token: \(tempPassword)")
                            
                            // Show alert to user
                            authViewModel.errorMessage = "Admin created! Setup token: \(tempPassword)"
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
