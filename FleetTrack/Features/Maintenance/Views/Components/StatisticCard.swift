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
<<<<<<< HEAD
        .cornerRadius(AppTheme.cornerRadius.medium)
=======
        .cornerRadius(AppTheme.cornerRadius.large)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
        .accessibilityIdentifier("maintenance_stat_card_\(label.lowercased().replacingOccurrences(of: " ", with: "_"))")
>>>>>>> d3dfd6b3ea8c3417c1942f194070d786fac23a9b
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
