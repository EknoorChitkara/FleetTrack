//
//  FleetManagerProfileView.swift
//  FleetTrack
//

import SwiftUI

struct FleetManagerProfileView: View {
    @Environment(\.presentationMode) var presentationMode

    let user: User
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationView {
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
                                presentationMode.wrappedValue.dismiss()
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
                            // Account Section
                            ProfileSection(title: "Account") {
                                NavigationLink(destination: FleetManagerManageDriversView()) {
                                    SettingRow(icon: "person.2.fill", title: "Manage Drivers", color: .blue)
                                }
                                NavigationLink(destination: AllTripsView()) {
                                    SettingRow(icon: "map.fill", title: "Trip History", color: .purple)
                                }
                            }
                            
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
                            Task {
                                try? await SupabaseAuthService.shared.logout()
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Logout")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditProfile) {
                FleetManagerEditProfileView(user: user)
            }
        }
    }
}

struct ProfileSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.appSecondaryText)
                .padding(.leading, 8)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.appCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding()
    }
}
