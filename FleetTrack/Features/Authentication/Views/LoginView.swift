//
//  LoginView.swift
//  FleetTrack
//
//  Created by Eknoor on 07/01/26.
//

import Supabase
import SwiftUI

struct LoginView: View {
    @ObservedObject private var sessionManager = SessionManager.shared

    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var message = ""
    @State private var isLoading = false
    @State private var show2FAView = false
    @State private var otpEmail = ""

    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        password.count >= 8
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "truck.box.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.appEmerald)
                    .shadow(color: .appEmerald.opacity(0.3), radius: 10)

                VStack(spacing: 8) {
                    Text("FleetTrack")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Precision Fleet Management")
                        .font(.subheadline)
                        .foregroundColor(.appSecondaryText)
                }

                Spacer().frame(height: 40)

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12).stroke(
                                Color.appSecondaryText.opacity(0.3), lineWidth: 1)
                        )
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    HStack {
                        if isPasswordVisible {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }

                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.appSecondaryText)
                        }
                    }
                    .padding()
                    .background(Color.appCardBackground)
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12).stroke(
                            Color.appSecondaryText.opacity(0.3), lineWidth: 1))
                }
                .padding(.horizontal)

                Button {
                    Task { await login() }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Sign In")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        isFormValid 
                        ? LinearGradient(
                            gradient: Gradient(colors: [.appEmerald, .appEmerald.opacity(0.8)]),
                            startPoint: .top, endPoint: .bottom)
                        : LinearGradient(
                            gradient: Gradient(colors: [.gray.opacity(0.5), .gray.opacity(0.3)]),
                            startPoint: .top, endPoint: .bottom)
                    )
                    .foregroundColor(isFormValid ? .white : .white.opacity(0.5))
                    .cornerRadius(12)
                    .shadow(color: isFormValid ? .appEmerald.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
                .disabled(isLoading || !isFormValid)

                Button("Forgot Password?") {
                    Task { await forgotPassword() }
                }
                .font(.subheadline)
                .foregroundColor(.appEmerald)

                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(message.contains("✅") ? .appEmeraldLight : .red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                Spacer()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationDestination(isPresented: $show2FAView) {
                VerificationView(email: otpEmail)
            }
        }
    }

    private func login() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            message = "❌ Please enter email and password"
            return
        }

        isLoading = true
        message = ""

        do {
            // Step 1: Verify Password using an isolated "Ghost Client"
            // We do this to avoid triggering the global SessionManager
            // until the 2FA (Step 2) is actually completed.
            let ghostClient = SupabaseClient(
                supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
                supabaseKey: SupabaseConfig.supabaseAnonKey,
                options: SupabaseClientOptions(
                    auth: .init(storage: isolatedStorage)
                )
            )
            
            try await ghostClient.auth.signIn(email: trimmedEmail, password: password)
            print("✅ Step 1: Password Verified (via Ghost Client)")

            // Step 2: Trigger Code Send on the MAIN client
            // signInWithOTP does NOT create a session, so it won't trigger RootView
            try await supabase.auth.signInWithOTP(email: trimmedEmail)
            print("✅ Step 2: Code Sent to \(trimmedEmail)")

            await MainActor.run {
                self.otpEmail = trimmedEmail
                self.show2FAView = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                print("❌ Login error: \(error)")
                Task {
                    let userExists = await checkUserExists(email: trimmedEmail)
                    let isFormatValid = ValidationHelpers.isValidEmail(trimmedEmail)
                    
                    await MainActor.run {
                        if !isFormatValid {
                            message = "❌ incorrect email"
                        } else if !userExists {
                            message = "❌ both password and email are incorrect"
                        } else {
                            message = "❌ password incorrect"
                        }
                        isLoading = false
                    }
                }
            }
        }
    }
    
    private func checkUserExists(email: String) async -> Bool {
        do {
            let count: Int = try await supabase
                .from("users")
                .select("*", head: true, count: .exact)
                .eq("email", value: email)
                .execute()
                .count ?? 0
            return count > 0
        } catch {
            print("❌ Error checking user existence: \(error)")
            return false
        }
    }
    
    // Helper to keep Ghost Client session isolated
    private var isolatedStorage: AuthLocalStorage {
        class NoOpStorage: AuthLocalStorage {
            func store(key: String, value: Data) throws {}
            func retrieve(key: String) throws -> Data? { return nil }
            func remove(key: String) throws {}
        }
        return NoOpStorage()
    }

    private func forgotPassword() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            message = "❌ Enter your email first"
            return
        }
        isLoading = true
        message = ""
        
        do {
            // Use reset-password redirect so FleetTrackApp handles it correctly
            try await supabase.auth.resetPasswordForEmail(
                trimmedEmail,
                redirectTo: URL(string: "fleettrack://reset-password")
            )
            message = "✅ Password reset link sent to \(trimmedEmail)"
        } catch {
            print("❌ Forgot password error: \(error)")
            message = "❌ Failed to send reset link. Please try again."
        }
        isLoading = false
    }
}
