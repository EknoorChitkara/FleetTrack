//
//  StatisticCard.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//


import SwiftUI

struct StatisticCard: View {
    let icon: String
    let value: String
    let label: String
    let iconBackgroundColor: Color
    
    var body: some View {
        VStack(spacing: AppTheme.spacing.md) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(AppTheme.accentPrimary.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppTheme.accentPrimary)
            }
            
            // Value
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120) // Match TaskCountBox height
        .padding(AppTheme.spacing.lg)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.large)
    }
}

#Preview {
    HStack {
        StatisticCard(
            icon: "checkmark",
            value: "45",
            label: "Completed This Month",
            iconBackgroundColor: AppTheme.statusActiveBackground
        )
        
        StatisticCard(
            icon: "clock",
            value: "2.5h",
            label: "Avg Completion Time",
            iconBackgroundColor: AppTheme.backgroundElevated
        )
    }
    .padding()
    .background(AppTheme.backgroundPrimary)
}
