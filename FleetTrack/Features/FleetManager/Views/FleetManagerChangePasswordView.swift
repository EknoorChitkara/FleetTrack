//
//  FleetManagerChangePasswordView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct FleetManagerChangePasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    var body: some View {
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
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Back")
                    .accessibilityIdentifier("change_password_back_button")
                    
                    Spacer()
                    
                    Text("Change Password")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Form
                VStack(spacing: 20) {
                    AuthTextField(title: "Current Password", text: $currentPassword)
                    AuthTextField(title: "New Password", text: $newPassword)
                    AuthTextField(title: "Confirm Password", text: $confirmPassword)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Button
                Button(action: {
                    // Logic
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Change Password")
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appEmerald) // Green button
                        .cornerRadius(12)
                }
                .accessibilityLabel("Change Password")
                .accessibilityHint("Double tap to update your password")
                .accessibilityIdentifier("change_password_submit_button")
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

// Reusing a style similar to other auth fields
struct AuthTextField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            SecureField("", text: $text)
                .padding()
                .background(Color(white: 0.15))
                .cornerRadius(8)
                .foregroundColor(.white)
                .accessibilityLabel(title)
                .accessibilityIdentifier("change_password_field_\(title.lowercased().replacingOccurrences(of: " ", with: "_"))")
        }
    }
}
