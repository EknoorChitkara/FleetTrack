//
//  VerificationView.swift
//  FleetTrack
//
//  Created by Eknoor on 07/01/26.
//

import SwiftUI
import Supabase

struct VerificationView: View {
    let email: String
    @Binding var isLoggedIn: Bool
    @Binding var currentUser: User?
    
    @Environment(\.dismiss) var dismiss
    @State private var otpCode: [String] = Array(repeating: "", count: 8)
    @FocusState private var focusedIndex: Int?
    @State private var isLoading = false
    @State private var message = ""
    
    var body: some View {
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
                
                HStack(spacing: 8) {
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
    }
    
    private func verifyCode() async {
        guard !isLoading else { return }
        isLoading = true
        let fullCode = otpCode.joined().trimmingCharacters(in: .whitespaces)
        
        do {
            try await supabase.auth.verifyOTP(
                email: email,
                token: fullCode,
                type: .magiclink
            )
            print("✅ 2FA Success for \(email)")
            
            // Fetch User profile after verification
            let session = try await supabase.auth.session
            let userProfile: User = try await supabase
                .from("users")
                .select()
                .eq("id", value: session.user.id)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.currentUser = userProfile
                self.isLoggedIn = true
                self.isLoading = false
            }
        } catch {
            print("❌ Verification Error: \(error)")
            await MainActor.run {
                message = "❌ Invalid or expired code"
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
