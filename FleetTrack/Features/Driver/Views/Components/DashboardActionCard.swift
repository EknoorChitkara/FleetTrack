//
//  DashboardActionCard.swift
//  FleetTrack
//
//

import SwiftUI

struct DashboardActionCard: View {
    let action: DashboardAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon Container
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appCardBackground.opacity(0.5)) // Slightly lighter/darker
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: action.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(action.iconColor ?? .white)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(action.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(action.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.appSecondaryText)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.appSecondaryText)
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
