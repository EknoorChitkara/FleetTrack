//
//  MaintenanceAboutView.swift
//  FleetTrack
//

import SwiftUI

struct MaintenanceAboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
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
                    .accessibilityLabel("Back")
                    .accessibilityIdentifier("maintenance_about_back_button")
                    
                    Spacer()
                    
                    Text("About")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                .padding(.top)
                
                Spacer()
                
                // App Info
                VStack(spacing: 20) {
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppTheme.accentPrimary)
                    
                    Text("Fleet Dashboard")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Version 1.0.0")
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text("© 2026 Fleet Dashboard Inc.\nAll rights reserved.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.top, 10)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Fleet Dashboard, Version 1.0.0. Copyright 2026 Fleet Dashboard Inc.")
                .accessibilityIdentifier("maintenance_about_info")
                
                Spacer()
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    MaintenanceAboutView()
}
