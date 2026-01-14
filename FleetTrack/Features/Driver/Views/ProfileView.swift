//
//  ProfileView.swift
//  FleetTrack
//
//  Created for Driver
//

import SwiftUI

struct ProfileView: View {
    @Binding var user: User
    @Binding var driver: Driver
    @State private var showEditProfile = false
    @State private var isLoggingOut = false
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var sessionManager = SessionManager.shared
    
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
                                
                                // Clean layout for driver info
                                if let phone = driver.phoneNumber ?? user.phoneNumber {
                                    Text(phone)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.top, 2)
                                }
                            }
                            
                            Button(action: {
                                showEditProfile = true
                            }) {
                                Text("Edit Profile")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                    .background(Color.appEmerald)
                                    .cornerRadius(20)
                            }
                        }
                        
                        // Settings Sections
                        VStack(spacing: 24) {

                            
                            // Security Section
                            DriverProfileSection(title: "Security & Privacy") {
                                NavigationLink(destination: DriverChangePasswordView()) {
                                    DriverSettingRow(icon: "lock.fill", title: "Change Password", color: .orange)
                                }
                                NavigationLink(destination: DriverPrivacyView()) {
                                    DriverSettingRow(icon: "shield.fill", title: "Privacy Policy", color: .green)
                                }
                            }

                            
                            // Support Section
                            DriverProfileSection(title: "Support") {
                                NavigationLink(destination: DriverHelpSupportView()) {
                                    DriverSettingRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .blue)
                                }
                                NavigationLink(destination: DriverAboutView()) {
                                    DriverSettingRow(icon: "info.circle.fill", title: "About FleetTrack", color: .gray)
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
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(user: $user, driver: $driver, isPresented: $showEditProfile)
            }
        }
    }
}

// MARK: - Subviews

// Renamed to avoid redeclaration conflict with FleetManager version
struct DriverProfileSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.leading, 8)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
    }
}


// Renamed to avoid redeclaration conflict with FleetManager version
struct DriverSettingRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}



#Preview {
    ProfileView(user: .constant(.mockDriver), driver: .constant(.mockDriver1))
}
