//
//  FleetManagerEditProfileView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct FleetManagerEditProfileView: View {
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
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .padding(10)
                            .background(Color(white: 0.2))
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Back")
                    .accessibilityIdentifier("edit_profile_back_button")
                    
                    Spacer()
                    
                    Text("Edit Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                    
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
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Full Name", text: $fullName)
                            .padding()
                            .background(Color(white: 0.15))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .accessibilityLabel("Full Name")
                            .accessibilityIdentifier("edit_profile_name_field")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Role")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(user.role.rawValue) // Read only
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(white: 0.15).opacity(0.5))
                            .cornerRadius(8)
                            .foregroundColor(.gray)
                            .accessibilityLabel("Role: \(user.role.rawValue)")
                            .accessibilityIdentifier("edit_profile_role_read_only")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Email", text: $email)
                            .padding()
                            .background(Color(white: 0.15))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .accessibilityLabel("Email Address")
                            .accessibilityIdentifier("edit_profile_email_field")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Phone", text: $phone)
                            .padding()
                            .background(Color(white: 0.15))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .accessibilityLabel("Phone Number")
                            .accessibilityIdentifier("edit_profile_phone_field")
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Save Button
                Button(action: {
                    // Save Logic
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save Changes")
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appEmerald)
                        .cornerRadius(12)
                }
                .accessibilityLabel("Save Changes")
                .accessibilityHint("Double tap to save your profile changes")
                .accessibilityIdentifier("edit_profile_save_button")
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        }
    }
}
