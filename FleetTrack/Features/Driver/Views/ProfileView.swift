//
//  ProfileView.swift
//  FleetTrack
//
//  Created for Driver App
//

import SwiftUI

struct ProfileView: View {
    @Binding var user: User
    @Binding var driver: Driver
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var sessionManager = SessionManager.shared
    
    @State private var isShowingEditProfile = false
    @State private var isLoggingOut = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        HStack {
                            Text("Profile")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            }
                            .accessibilityLabel("Close Profile")
                            .accessibilityHint("Double tap to close profile view")
                            .accessibilityIdentifier("profile_close_button")
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // User Info Card
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.appEmerald.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                
                                Text(user.initials)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.appEmerald)
                            }
                            
                            VStack(spacing: 4) {
                                Text(user.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.appSecondaryText)
                            }
                            
                            Button(action: {
                                isShowingEditProfile = true
                            }) {
                                Text("Edit Profile")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                    .background(Color.appEmerald)
                                    .cornerRadius(20)
                            }
                            .accessibilityLabel("Edit Profile")
                            .accessibilityHint("Double tap to edit your personal details")
                            .accessibilityIdentifier("profile_edit_button")
                        }
                        
                        // Settings Sections
                        VStack(spacing: 24) {

                            
                            // Security Section
                            ProfileSection(title: "Security & Privacy") {
                                NavigationLink(destination: FleetManagerChangePasswordView()) {
                                    SettingRow(icon: "lock.fill", title: "Change Password", color: .orange)
                                }
                                NavigationLink(destination: FleetManagerPrivacyView()) {
                                    SettingRow(icon: "shield.fill", title: "Privacy Policy", color: .green)
                                }
                            }
                            
                            // Support Section
                            ProfileSection(title: "Support") {
                                NavigationLink(destination: FleetManagerHelpSupportView()) {
                                    SettingRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .blue)
                                }
                                NavigationLink(destination: FleetManagerAboutView()) {
                                    SettingRow(icon: "info.circle.fill", title: "About FleetTrack", color: .gray)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Logout Button
                        Button(action: {
                            isLoggingOut = true
                            Task {
                                try? await SupabaseAuthService.shared.logout()
                                sessionManager.clearSession()
                                isLoggingOut = false
                                dismiss()
                            }
                        }) {
                            HStack {
                                if isLoggingOut {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Logout")
                                        .fontWeight(.bold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(12)
                        }
                        .disabled(isLoggingOut)
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                        .accessibilityLabel("Logout")
                        .accessibilityHint("Double tap to sign out of your account")
                        .accessibilityIdentifier("profile_logout_button")
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingEditProfile) {
                EditProfileView(user: $user, driver: $driver, isPresented: $isShowingEditProfile)
                    .preferredColorScheme(.dark)
            }
        }
    }
}



#Preview {
    ProfileView(user: .constant(.mockDriver), driver: .constant(.mockDriver1))
}
