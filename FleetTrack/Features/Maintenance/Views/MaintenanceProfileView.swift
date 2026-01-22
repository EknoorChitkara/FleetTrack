//
//  MaintenanceProfileView.swift
//  FleetTrack
//
//  Created for Maintenance personnel
//

import SwiftUI

struct MaintenanceProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    let user: User
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        HStack {
                            Text("Profile")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .accessibilityAddTraits(.isHeader)
                            Spacer()
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .accessibilityLabel("Close")
                            .accessibilityIdentifier("maintenance_profile_close_button")
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // User Info Card
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accentPrimary.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                
                                Text(user.initials)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(AppTheme.accentPrimary)
                            }
                            
                            VStack(spacing: 4) {
                                Text(user.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("User: \(user.name), Email: \(user.email)")
                            .accessibilityIdentifier("maintenance_profile_user_info")
                            
                            Button(action: {
                                showEditProfile = true
                            }) {
                                Text("Edit Profile")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                    .background(AppTheme.accentPrimary)
                                    .cornerRadius(20)
                            }
                            .accessibilityLabel("Edit Profile")
                            .accessibilityIdentifier("maintenance_profile_edit_button")
                        }
                        
                        // Settings Sections
                        VStack(spacing: 24) {
                            // Security Section
                            MaintenanceProfileSection(title: "Security & Privacy") {
                                NavigationLink(destination: MaintenanceChangePasswordView()) {
                                    MaintenanceSettingRow(icon: "lock.fill", title: "Change Password", color: .orange)
                                }
                                NavigationLink(destination: MaintenancePrivacyView()) {
                                    MaintenanceSettingRow(icon: "shield.fill", title: "Privacy Policy", color: Color(hex: "2D7D46"))
                                }
                            }
                            
                            // Voice Settings
                            MaintenanceProfileSection(title: "Accessibility") {
                                Toggle(isOn: Binding(
                                    get: { InAppVoiceSettings.shared.isVoiceEnabled },
                                    set: { _ in InAppVoiceManager.shared.toggleVoiceMode() }
                                )) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.appEmerald.opacity(0.1))
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: "waveform.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(.appEmerald)
                                        }
                                        
                                        Text("Voice Narration")
                                            .font(.system(size: 16))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                }
                                .padding()
                            }
                            
                            // Support Section
                            MaintenanceProfileSection(title: "Support") {
                                NavigationLink(destination: MaintenanceHelpSupportView()) {
                                    MaintenanceSettingRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .blue)
                                }
                                NavigationLink(destination: MaintenanceAboutView()) {
                                    MaintenanceSettingRow(icon: "info.circle.fill", title: "About FleetTrack", color: .gray)
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
                        .accessibilityLabel("Logout")
                        .accessibilityIdentifier("maintenance_profile_logout_button")
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditProfile) {
                MaintenanceEditProfileView(user: user)
            }
        }
    }
}

struct MaintenanceProfileSection<Content: View>: View {
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
                .foregroundColor(AppTheme.textSecondary)
                .padding(.leading, 8)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: 0) {
                content
            }
            .background(AppTheme.backgroundSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.textSecondary.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct MaintenanceSettingRow: View {
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
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint("Go to \(title)")
        .accessibilityIdentifier("maintenance_setting_row_\(title.lowercased().replacingOccurrences(of: " ", with: "_"))")
    }
}

#Preview {
    MaintenanceProfileView(user: .testAdmin())
}
