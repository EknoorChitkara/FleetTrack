//
//  DriverPrivacyView.swift
//  FleetTrack
//
//  Created by srishti  on 13/01/26.
//

import SwiftUI

struct DriverPrivacyView: View {
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
                    
                    Text("Privacy & Security")
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
                            title: "Data Privacy",
                            content: "We take your data privacy seriously. All your personal information and fleet maintenance data are encrypted using industry-standard protocols.",
                            color: AppTheme.accentPrimary
                        )
                        
                        MaintenancePrivacyCard(
                            title: "Security",
                            content: "Our platform implements multi-factor authentication and regular security audits to ensure your account remains safe.",
                            color: AppTheme.accentPrimary
                        )
                        
                        MaintenancePrivacyCard(
                            title: "Data Sharing",
                            content: "We do not share your personal data with third parties without your explicit consent.",
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

struct DriverPrivacyCard: View {
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            
            Text(content)
                .font(.body)
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(12)
    }
}

#Preview {
    DriverPrivacyView()
}
