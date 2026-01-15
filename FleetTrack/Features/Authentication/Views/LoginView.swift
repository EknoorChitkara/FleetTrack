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
    @State private var message = ""
    @State private var isLoading = false
    @State private var show2FAView = false
    @State private var otpEmail = ""

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

                    SecureField("Password", text: $password)
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
                        LinearGradient(
                            gradient: Gradient(colors: [.appEmerald, .appEmerald.opacity(0.8)]),
                            startPoint: .top, endPoint: .bottom)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .appEmerald.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
                .disabled(isLoading)

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
            // Step 1: Verify Password
            try await supabase.auth.signIn(email: trimmedEmail, password: password)
            print("✅ Step 1: Password Verified")

            // Step 2: Clear session to ensure clean OTP flow
            // This prevents "otp_expired" conflicts
            try? await supabase.auth.signOut()

            // Small delay to let Supabase settle
            try? await Task.sleep(for: .seconds(1))

            // Step 3: Trigger Code Send
            try await supabase.auth.signInWithOTP(email: trimmedEmail)
            print("✅ Step 2: OTP Sent to \(trimmedEmail)")

            await MainActor.run {
                self.otpEmail = trimmedEmail
                self.show2FAView = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                print("❌ Login error: \(error)")
                message = "❌ Invalid email or password"
                isLoading = false
            }
        }
    }

    private func forgotPassword() async {
        guard !email.isEmpty else {
            message = "❌ Enter email first"
            return
        }
        isLoading = true
        do {
            try await supabase.auth.resetPasswordForEmail(
                email, redirectTo: URL(string: "fleettrack://auth/callback"))
            message = "✅ Reset link sent!"
        } catch {
            message = "❌ \(error.localizedDescription)"
        }
        isLoading = false
    }
}
