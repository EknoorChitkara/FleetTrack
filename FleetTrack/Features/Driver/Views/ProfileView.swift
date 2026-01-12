//
//  ProfileView.swift
//  FleetTrack
//

import SwiftUI

struct ProfileView: View {
    @Binding var user: User
    @Binding var driver: Driver
    @State private var isShowingEditProfile = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        ProfileHeaderView(user: user, driver: driver, isShowingEditProfile: $isShowingEditProfile)
                        
                        // Account Settings
                        SectionCard(title: "Account Settings") {
                            SettingsRow(icon: "lock.fill", iconColor: AppTheme.iconDefault, title: "Change Password")
                            Divider().background(AppTheme.dividerPrimary)
                            SettingsRow(icon: "shield.fill", iconColor: AppTheme.iconDefault, title: "Privacy & Security")
                            Divider().background(AppTheme.dividerPrimary)
                            SettingsRow(icon: "bell.fill", iconColor: AppTheme.iconDefault, title: "Notification Settings", badgeCount: 3)
                        }
                        
                        // App Settings
                        SectionCard(title: "App Settings") {
                            SettingsRow(icon: "slider.horizontal.3", iconColor: AppTheme.iconDefault, title: "Preferences")
                            Divider().background(AppTheme.dividerPrimary)
                            SettingsRow(icon: "questionmark.circle.fill", iconColor: AppTheme.iconDefault, title: "Help & Support")
                            Divider().background(AppTheme.dividerPrimary)
                            SettingsRow(icon: "info.circle.fill", iconColor: AppTheme.iconDefault, title: "About")
                        }
                        
                        LogoutButton(dismissRoot: dismiss)
                        
                        Spacer().frame(height: 100)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Profile")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $isShowingEditProfile) {
                EditProfileView(user: $user, driver: $driver, isPresented: $isShowingEditProfile)
                    .preferredColorScheme(.dark)
            }
        }
    }
}

// MARK: - Subviews

struct ProfileHeaderView: View {
    let user: User
    let driver: Driver
    @Binding var isShowingEditProfile: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(AppTheme.backgroundElevated)
                        .frame(width: 80, height: 80)
                    
                    Text(user.initials)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(user.role.rawValue)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            Divider()
                .background(AppTheme.dividerPrimary)
                .padding(.vertical, 16)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "envelope")
                        .foregroundColor(AppTheme.iconDefault)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "phone")
                        .foregroundColor(AppTheme.iconDefault)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Phone")
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                        Text(user.phoneNumber ?? "Not set")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
            .padding(.horizontal)
            
            Button(action: {
                isShowingEditProfile = true
            }) {
                Text("Edit Profile")
                    .font(.headline)
                    .foregroundColor(AppTheme.backgroundPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.backgroundSecondary)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.dividerPrimary, lineWidth: 1)
                    )
            }
            .padding(.all, 20)
        }
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal)
                .padding(.top, 16)
            
            VStack(spacing: 0) {
                content
            }
            .background(AppTheme.backgroundSecondary)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var badgeCount: Int? = nil
    
    var body: some View {
        Button(action: {
            // Navigation Action
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                if let count = badgeCount {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding()
        }
    }
}

struct LogoutButton: View {
    var dismissRoot: DismissAction
    
    var body: some View {
        Button(action: {
            Task {
                try? await SupabaseAuthService.shared.logout()
                // The app will react to session change in FleetTrackApp
                dismissRoot()
            }
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .rotationEffect(.degrees(180))
                Text("Logout")
            }
            .font(.headline)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.backgroundSecondary)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

#Preview {
    ProfileView(user: .constant(.mockDriver), driver: .constant(.mockDriver1))
}
