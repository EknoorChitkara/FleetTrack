//
//  MaintenanceHelpSupportView.swift
//  FleetTrack
//

import SwiftUI

struct MaintenanceHelpSupportView: View {
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
                    
                    Text("Help & Support")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                .padding(.top)
                
                ScrollView {
                    VStack(spacing: 16) {
                        MaintenancePrivacyCard(
                            title: "Contact Support",
                            content: "Need help? Reach out to our support team at support@fleetdashboard.com or call us at 1-800-FLEET-HELP.",
                            color: AppTheme.accentPrimary
                        )
                        
                        MaintenancePrivacyCard(
                            title: "FAQ",
                            content: "Check our website for frequently asked questions about vehicle tracking, maintenance tasks, and diagnostics.",
                            color: AppTheme.accentPrimary
                        )
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    MaintenanceHelpSupportView()
}
