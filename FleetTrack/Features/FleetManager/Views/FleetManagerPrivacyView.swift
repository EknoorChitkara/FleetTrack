//
//  FleetManagerPrivacyView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct FleetManagerPrivacyView: View {
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
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Back")
                    .accessibilityIdentifier("privacy_back_button")
                    
                    Spacer()
                    
                    Text("Privacy & Security")
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
                            title: "Data Privacy",
                            content: "We take your data privacy seriously. All your personal information and fleet data are encrypted using industry-standard protocols.",
                            color: .appEmerald
                        )
                        
                        PrivacyCard(
                            title: "Security",
                            content: "Our platform implements multi-factor authentication and regular security audits to ensure your account remains safe.",
                            color: .appEmerald
                        )
                        
                        PrivacyCard(
                            title: "Data Sharing",
                            content: "We do not share your personal data with third parties without your explicit consent.",
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

struct PrivacyCard: View {
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
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(content)")
        .accessibilityIdentifier("privacy_card_\(title.lowercased().replacingOccurrences(of: " ", with: "_"))")
    }
}
