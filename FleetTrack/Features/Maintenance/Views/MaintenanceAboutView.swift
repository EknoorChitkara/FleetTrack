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
                    
                    Spacer()
                    
                    Text("About")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
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
