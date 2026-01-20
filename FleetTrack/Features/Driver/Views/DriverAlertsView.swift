//
//  DriverAlertsView.swift
//  FleetTrack
//
//  Created by FleetTrack
//

import SwiftUI

struct DriverAlertsView: View {
    @StateObject private var viewModel = DriverAlertsViewModel()
    
    var body: some View {
        ZStack {
            Color(hex: "111111").ignoresSafeArea() // Deep black/grey background
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Alerts")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        Task { await viewModel.refresh() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.green)
                    Spacer()
                } else if viewModel.alerts.isEmpty {
                    Spacer()
                    EmptyStateView()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.alerts) { alert in
                                AlertCell(alert: alert)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .onAppear {
            Task { await viewModel.loadAlerts() } // Ensure data is loaded on appear
        }
    }
}

// MARK: - Subviews

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color(hex: "2E8B57") : Color(hex: "2C2C2E")) // Green or Dark Grey
                )
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No alerts to display")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
    }
}

struct AlertCell: View {
    let alert: MaintenanceAlert
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon based on type
            ZStack {
                Circle()
                    .fill(Color(hex: "2C2C2E"))
                    .frame(width: 44, height: 44)
                
                Image(systemName: alert.type == .emergency ? "exclamationmark.triangle.fill" : "wrench.and.screwdriver.fill")
                    .foregroundColor(alert.type == .emergency ? .red : .orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(timeAgo(from: alert.date))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Text(alert.message)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1C1C1E")) // Slightly lighter card bg
        )
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
     }
}

// Helper for Hex Color if not present in codebase extensions


#Preview {
    DriverAlertsView()
}
