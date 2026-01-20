//
//  TodaysTaskCard.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import SwiftUI

struct TodaysTasksCard: View {
    let pendingCount: Int
    let inProgressCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            Text("Summary")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            HStack(spacing: AppTheme.spacing.md) {
                // Pending Tasks
                TaskCountBox(
                    title: "Pending",
                    count: pendingCount,
                    backgroundColor: AppTheme.backgroundElevated
                )
                
                // In Progress Tasks
                TaskCountBox(
                    title: "In Progress",
                    count: inProgressCount,
                    backgroundColor: AppTheme.backgroundElevated,
                    iconColor: Color.yellow,
                    iconBackgroundColor: Color.yellow.opacity(0.15)
                )
            }
        }
    }
}

struct TaskCountBox: View {
    let title: String
    let count: Int
    let backgroundColor: Color
    var iconColor: Color = AppTheme.accentPrimary
    var iconBackgroundColor: Color = AppTheme.accentPrimary.opacity(0.15)
    
    var body: some View {
        VStack(spacing: AppTheme.spacing.md) {
            // Icon with circular background
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 48, height: 48)
                
                Image(systemName: iconForTitle)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Text("\(count)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .padding(AppTheme.spacing.lg)
        .background(backgroundColor)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
    
    private var iconForTitle: String {
        switch title {
        case "Pending":
            return "clock.badge.exclamationmark"
        case "In Progress":
            return "gearshape.2"
        default:
            return "star"
        }
    }
}

#Preview {
    TodaysTasksCard(pendingCount: 5, inProgressCount: 3)
        .padding()
        .background(AppTheme.backgroundPrimary)
}
