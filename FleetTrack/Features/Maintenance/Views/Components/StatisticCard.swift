//
//  StatisticCard.swift
//  FleetTrack
//
//  Created for Maintenance Module - Dashboard Statistics
//

import SwiftUI

struct StatisticCard: View {
    let icon: String
    let value: String
    let label: String
    let iconBackgroundColor: Color
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: AppTheme.spacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }
            
            // Value
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)
            
            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
}

#Preview {
    StatisticCard(
        icon: "chart.bar.fill",
        value: "24",
        label: "Completed This Month",
        iconBackgroundColor: Color.purple.opacity(0.15),
        iconColor: Color.purple
    )
    .padding()
    .background(AppTheme.backgroundPrimary)
}
