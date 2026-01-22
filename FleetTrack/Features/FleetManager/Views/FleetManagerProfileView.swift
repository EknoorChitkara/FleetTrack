//
//  FleetManagerProfileView.swift
//  FleetTrack
//

import SwiftUI

struct FleetManagerProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fleetVM: FleetViewModel
    @ObservedObject private var sessionManager = SessionManager.shared
    let user: User
    @State private var showEditProfile = false
    @State private var isLoggingOut = false
    
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
                            .accessibilityLabel("Close")
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
                            .accessibilityLabel("Edit Profile")
                            .accessibilityHint("Double tap to edit your profile information")
                            .accessibilityIdentifier("profile_edit_button")
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("User \(user.name), Email \(user.email)")
                        .accessibilityIdentifier("user_info_section")
                        
                        // Settings Sections
                        VStack(spacing: 24) {
                            // Account Section
                            ProfileSection(title: "Account") {
                                NavigationLink(destination: FleetManagerManageDriversView().environmentObject(fleetVM)) {
                                    SettingRow(icon: "person.2.fill", title: "Manage Drivers", color: .blue)
                                }
                                NavigationLink(destination: AllTripsView().environmentObject(fleetVM)) {
                                    SettingRow(icon: "map.fill", title: "Trip History", color: .purple)
                                }
                            }

                            // Voice Settings
                            ProfileSection(title: "Accessibility") {
                                Toggle(isOn: Binding(
                                    get: { InAppVoiceSettings.shared.isVoiceEnabled },
                                    set: { _ in InAppVoiceManager.shared.toggleVoiceMode() }
                                )) {
                                    HStack {
                                        Image(systemName: "waveform.circle.fill")
                                            .foregroundColor(.appEmerald)
                                            .font(.system(size: 20))
                                        Text("Voice Narration")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(Color.appCardBackground)
                                .cornerRadius(12)
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
                            isLoggingOut = true
                            Task {
                                try? await SupabaseAuthService.shared.logout()
                                sessionManager.clearSession()
                                isLoggingOut = false
                                presentationMode.wrappedValue.dismiss()
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
                        .accessibilityLabel("Logout")
                        .accessibilityHint("Double tap to log out of your account")
                        .accessibilityIdentifier("profile_logout_button")
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
                .accessibilityAddTraits(.isHeader)
            
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint("Go to \(title)")
        .accessibilityIdentifier("setting_row_\(title.lowercased().replacingOccurrences(of: " ", with: "_"))")
    }
}
