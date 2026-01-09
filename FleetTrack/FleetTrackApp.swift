//
//  FleetTrackApp.swift
//  FleetTrack
//
//  Created by Eknoor on 07/01/26.
//

import SwiftUI
import Supabase

// Global Supabase client
nonisolated(unsafe) let supabaseClient: SupabaseClient = {
    return SupabaseClient(
        supabaseURL: URL(string: "https://aqvcmemepiupasgozdei.supabase.co")!,
        supabaseKey: "sb_publishable_BWUDyIK9C8RxkWgkJhCx5A_34dcG1rT"
    )
}()

@main
struct FleetTrackApp: App {
    @State private var deepLinkData: DeepLinkData?
    @State private var currentUser: User?
    @State private var isLoggedIn = false
    
    struct DeepLinkData: Identifiable {
        let id = UUID()
        let url: URL
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn, let user = currentUser {
                    NavigationStack {
                        switch user.role {
                        case .fleetManager: FleetManagerDashboardView(user: user).toolbar { logoutButton }
                        case .driver: DriverDashboardView(user: user).toolbar { logoutButton }
                        case .maintenancePersonnel: MaintenanceDashboardView(user: user).toolbar { logoutButton }
                        }
                    }
                } else {
                    LoginView(isLoggedIn: $isLoggedIn, currentUser: $currentUser)
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .sheet(item: $deepLinkData) { data in
                ResetPasswordView(url: data.url)
            }
        }
    }
    
    private var logoutButton: ToolbarItem<(), Button<some View>> {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Task {
                    try? await supabaseClient.auth.signOut()
                    isLoggedIn = false
                    currentUser = nil
                }
            } label: {
                Text("Logout")
                    .foregroundColor(.appEmerald)
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        print("✅ App opened via deep link: \(url.absoluteString)")
        
        // Use Identifiable item to ensure URL is present when sheet opens
        self.deepLinkData = DeepLinkData(url: url)
    }
}

// MARK: - Login View

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUser: User?
    
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isLoading = false
    @State private var show2FAView = false
    @State private var otpEmail = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
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
                        TextField("", text: $email, prompt: Text("Email").foregroundColor(.appSecondaryText))
                            .padding()
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appSecondaryText.opacity(0.3), lineWidth: 1))
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("", text: $password, prompt: Text("Password").foregroundColor(.appSecondaryText))
                            .padding()
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appSecondaryText.opacity(0.3), lineWidth: 1))
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
                            LinearGradient(gradient: Gradient(colors: [.appEmerald, .appEmerald.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
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
                    
                }
            }
            .navigationDestination(isPresented: $show2FAView) {
                VerificationView(email: otpEmail, isLoggedIn: $isLoggedIn, currentUser: $currentUser)
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
            try await supabaseClient.auth.signIn(email: trimmedEmail, password: password)
            print("✅ Step 1: Password Verified")
            
            // Step 2: Clear session to ensure clean OTP flow
            // This prevents "otp_expired" conflicts
            try? await supabaseClient.auth.signOut() 
            
            // Small delay to let Supabase settle
            try? await Task.sleep(for: .seconds(1))
            
            // Step 3: Trigger Code Send
            try await supabaseClient.auth.signInWithOTP(email: trimmedEmail)
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
            try await supabaseClient.auth.resetPasswordForEmail(email, redirectTo: URL(string: "fleettrack://auth/callback"))
            message = "✅ Reset link sent!"
        } catch {
            message = "❌ \(error.localizedDescription)"
        }
        isLoading = false
    }
}

// MARK: - Reset Password View

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
                try await supabaseClient.auth.setSession(accessToken: accessToken, refreshToken: refreshToken)
                print("✅ Session active! User: \(try? await supabaseClient.auth.session.user.email ?? "unknown")")
                isSessionSet = true
                return
            } catch {
                print("❌ Manual Session Error: \(error)")
            }
        }
        
        // 2. Fallback to helper
        do {
            try await supabaseClient.auth.session(from: url)
            print("✅ Helper Session Success")
            isSessionSet = true
        } catch {
            print("❌ All session attempts failed: \(error)")
            message = "❌ Session failed. Link might be expired or used."
            isSessionSet = true
        }
    }
    
    private func updatePassword() async {
        guard newPassword == confirmPassword else { message = "❌ Match error"; return }
        
        let currentSession = try? await supabaseClient.auth.session
        print("👤 Current session before update: \(currentSession?.user.email ?? "NIL")")
        
        isLoading = true
        do {
            try await supabaseClient.auth.update(user: .init(password: newPassword))
            message = "✅ Updated!"; try? await Task.sleep(for: .seconds(1))
            dismiss()
        } catch {
            message = "❌ \(error.localizedDescription)"
        }
        isLoading = false
    }
}

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
                    Task { try? await supabaseClient.auth.signInWithOTP(email: email) }
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
            try await supabaseClient.auth.verifyOTP(email: email, token: fullCode, type: .magiclink)
            print("✅ 2FA Success for \(email)")
            
            // Fetch User profile after verification
            let session = try await supabaseClient.auth.session
            let userProfile: User = try await supabaseClient.database
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
