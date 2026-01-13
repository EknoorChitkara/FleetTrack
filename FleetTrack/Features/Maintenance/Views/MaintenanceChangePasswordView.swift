//
//  MaintenanceChangePasswordView.swift
//  FleetTrack
//

import SwiftUI

struct MaintenanceChangePasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    var body: some View {
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
                    
                    Spacer()
                    
                    Text("Change Password")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Form
                VStack(spacing: 20) {
                    MaintenanceAuthTextField(title: "Current Password", text: $currentPassword)
                    MaintenanceAuthTextField(title: "New Password", text: $newPassword)
                    MaintenanceAuthTextField(title: "Confirm Password", text: $confirmPassword)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Button
                Button(action: {
                    // Logic would go here
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Change Password")
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accentPrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

struct MaintenanceAuthTextField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            
            SecureField("", text: $text)
                .padding()
                .background(AppTheme.backgroundSecondary)
                .cornerRadius(8)
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}

#Preview {
    MaintenanceChangePasswordView()
}
