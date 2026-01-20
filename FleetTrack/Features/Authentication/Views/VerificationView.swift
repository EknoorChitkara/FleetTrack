//  FleetTrack
//
//  Created by Eknoor on 07/01/26.
//

import SwiftUI
import Supabase
struct VerificationView: View {
    let email: String
    @ObservedObject private var sessionManager = SessionManager.shared

    
    @Environment(\.dismiss) var dismiss
    @State private var otpCode: [String] = Array(repeating: "", count: 8)
    @FocusState private var focusedIndex: Int?
    @State private var isLoading = false
    @State private var message = ""
    
    var body: some View {
        /*
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer().frame(height: 40)
                
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 80))
                    .foregroundColor(.appEmerald)
                    .shadow(color: .appEmerald.opacity(0.3), radius: 10)
                
                VStack(spacing: 8) {
                    Text("2FA Verification")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Enter the 8-digit code sent to\n\(email)")
                        .font(.subheadline)
                        .foregroundColor(.appSecondaryText)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 6) {
                    ForEach(0..<8, id: \.self) { index in
                        OTPInputBox(text: $otpCode[index], isFocused: focusedIndex == index)
                            .focused($focusedIndex, equals: index)
                            .onChange(of: otpCode[index]) { newValue in
                                if newValue.count > 1 {
                                    otpCode[index] = String(newValue.prefix(1))
                                }
                                if !newValue.isEmpty && index < 7 {
                                    focusedIndex = index + 1
                                }
                            }
                    }
                }
                .padding(.horizontal, 10)
                
                Button {
                    Task { await verifyCode() }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Verify")
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [.appEmerald, .appEmerald.opacity(0.8)]), startPoint: .top, endPoint: .bottom))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(isLoading || otpCode.contains(""))
                
                Button("Resend Code") {
                    Task { try? await supabase.auth.signInWithOTP(email: email) }
                }
                .font(.subheadline)
                .foregroundColor(.appEmerald)
                
                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(message.contains("✅") ? .appEmeraldLight : .red)
                        .font(.caption)
                        .padding()
                }
                
                Spacer()
            }
        }
        .onAppear { focusedIndex = 0 }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.appEmerald)
                }
            }
        }
        */
        Color.clear
    }
    
    private func verifyCode() async {
        guard !isLoading else { return }
        isLoading = true
        let fullCode = otpCode.joined().trimmingCharacters(in: .whitespaces)
        
        print("🔐 Attempting to verify OTP: \(fullCode) for email: \(email)")
        
        do {
            // Use .magiclink type since we used signInWithOTP(email:)
            let session = try await supabase.auth.verifyOTP(
                email: email,
                token: fullCode,
                type: .magiclink
            )
            print("✅ 2FA Success for \(email)")
            print("✅ Session user ID: \(session.user.id)")
            
            // Try to fetch existing user profile
            var userProfile: User?
            
            do {
                userProfile = try await supabase
                    .from("users")
                    .select()
                    .eq("id", value: session.user.id)
                    .single()
                    .execute()
                    .value
                print("✅ Existing user profile found: \(userProfile?.name ?? "Unknown")")
            } catch {
                // User doesn't exist in users table - create them
                print("⚠️ No user profile found, creating new record...")
                
                // Extract user info from auth session
                let userName = session.user.userMetadata["full_name"]?.stringValue ?? 
                               session.user.userMetadata["name"]?.stringValue ?? 
                               email.components(separatedBy: "@").first ?? "User"
                let userRole = session.user.userMetadata["role"]?.stringValue ?? "Driver"
                
                // Create new user record
                let newUser = User(
                    id: session.user.id,
                    name: userName,
                    email: email,
                    phoneNumber: session.user.phone,
                    role: UserRole(rawValue: userRole) ?? .driver,
                    profileImageURL: nil,
                    isActive: true,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                try await supabase
                    .from("users")
                    .insert(newUser)
                    .execute()
                
                userProfile = newUser
                print("✅ New user profile created for \(userName)")
            }
            
            guard let profile = userProfile else {
                throw NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to get or create user profile"])
            }
            
            print("✅ User profile ready: \(profile.name)")
            
            // Update SessionManager to trigger navigation
            await MainActor.run {
                self.sessionManager.setUser(profile)
                self.isLoading = false
            }
        } catch {
            print("❌ Verification Error: \(error)")
            await MainActor.run {
                message = "❌ Invalid or expired code. Please request a new code."
                // Clear boxes on failure to allow fresh entry
                otpCode = Array(repeating: "", count: 8)
                focusedIndex = 0
                isLoading = false
            }
        }
    }
}

struct OTPInputBox: View {
    @Binding var text: String
    var isFocused: Bool
    
    var body: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 20, weight: .bold))
            .frame(width: 38, height: 50)
            .background(Color.appCardBackground)
            .foregroundColor(.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Color.appEmerald : Color.appSecondaryText.opacity(0.3), lineWidth: 2)
            )
    }
}
