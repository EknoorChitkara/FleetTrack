//
//  MaintenanceEditProfileView.swift
//  FleetTrack
//
//  Created for Maintenance personnel
//

import SwiftUI

struct MaintenanceEditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    let user: User
    
    // State for form fields
    @State private var fullName: String
    @State private var email: String
    @State private var phone: String
    
    init(user: User) {
        self.user = user
        _fullName = State(initialValue: user.name)
        _email = State(initialValue: user.email)
        _phone = State(initialValue: user.phoneNumber ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20))
                                .padding(10)
                                .background(AppTheme.backgroundElevated)
                                .clipShape(Circle())
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .accessibilityLabel("Back")
                        .accessibilityIdentifier("maintenance_edit_profile_back_button")
                        
                        Spacer()
                        
                            Text("Edit Profile")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                                .accessibilityAddTraits(.isHeader)
                        
                        Spacer()
                        
                        Color.clear.frame(width: 40, height: 40)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Spacer().frame(height: 20)
                    
                    // Form
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Personal Information")
                            .font(.headline)
                            .foregroundColor(AppTheme.textSecondary)
                            .accessibilityAddTraits(.isHeader)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            TextField("Full Name", text: $fullName)
                                .padding()
                                .background(AppTheme.backgroundSecondary)
                                .cornerRadius(8)
                                .foregroundColor(AppTheme.textPrimary)
                                .accessibilityLabel("Full Name")
                                .accessibilityIdentifier("maintenance_profile_name_input")
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Role")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            Text(user.role.rawValue) // Read only
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(AppTheme.backgroundSecondary.opacity(0.5))
                                .cornerRadius(8)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            TextField("Email", text: $email)
                                .padding()
                                .background(AppTheme.backgroundSecondary)
                                .cornerRadius(8)
                                .foregroundColor(AppTheme.textPrimary)
                                .accessibilityLabel("Email")
                                .accessibilityIdentifier("maintenance_profile_email_input")
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            TextField("Phone", text: $phone)
                                .padding()
                                .background(AppTheme.backgroundSecondary)
                                .cornerRadius(8)
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Save Button
                    Button(action: {
                        // Save Logic - would call a service normally
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Save Changes")
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.accentPrimary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                    .accessibilityLabel("Save Changes")
                    .accessibilityIdentifier("maintenance_profile_save_button")
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    MaintenanceEditProfileView(user: .testAdmin())
}
