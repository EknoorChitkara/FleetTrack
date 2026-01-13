//
//  FleetManagerHelpSupportView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct FleetManagerHelpSupportView: View {
    @Environment(\.presentationMode) var presentationMode
    
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
                    
                    Text("Help & Support")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                .padding(.top)
                
                ScrollView {
                    VStack(spacing: 16) {
                        PrivacyCard(
                            title: "Contact Support",
                            content: "Need help? Reach out to our support team at support@fleetdashboard.com or call us at 1-800-FLEET-HELP.",
                            color: .appEmerald
                        )
                        
                        PrivacyCard(
                            title: "FAQ",
                            content: "Check our website for frequently asked questions about vehicle tracking, driver management, and billing.",
                            color: .appEmerald
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
