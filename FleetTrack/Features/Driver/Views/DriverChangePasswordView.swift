//
//  DriverChangePasswordView.swift
//  FleetTrack
//
//  Created for Driver
//

import SwiftUI

struct DriverChangePasswordView: View {
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
                            .background(Color(white: 0.2))
                            .clipShape(Circle())
                            .foregroundColor(.white)
                    }
                    
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
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}
