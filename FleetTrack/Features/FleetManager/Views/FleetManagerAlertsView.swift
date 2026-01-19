//
//  FleetManagerAlertsView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI
import Supabase

struct FleetManagerAlertsView: View {
    @State private var selectedSegment = 0
    @State private var alerts: [GeofenceAlert] = []
    @State private var isLoading = false
    @State private var selectedAlert: GeofenceAlert?
    
    var filteredAlerts: [GeofenceAlert] {
        if selectedSegment == 1 {
            return alerts.filter { !$0.isRead }
        }
        return alerts
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack(spacing: 8) {
                    Text("Alerts")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    if !alerts.filter({ !$0.isRead }).isEmpty {
                        Text("\(alerts.filter({ !$0.isRead }).count)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Button(action: { Task { await fetchAlerts() } }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.appEmerald)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Segment Control
                HStack(spacing: 12) {
                    AlertSegmentButton(title: "All (\(alerts.count))", isSelected: selectedSegment == 0) {
                        selectedSegment = 0
                    }
                    
                    AlertSegmentButton(title: "Unread (\(alerts.filter({ !$0.isRead }).count))", isSelected: selectedSegment == 1) {
                        selectedSegment = 1
                    }
                }
                .padding(.horizontal)
                
                if filteredAlerts.isEmpty {
                    Spacer()
                    // Empty State
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No alerts to display")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredAlerts) { alert in
                                AlertRowView(alert: alert)
                                    .onTapGesture {
                                        selectedAlert = alert
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .task {
            await fetchAlerts()
        }
        .sheet(item: $selectedAlert) { alert in
            AlertDetailView(alert: alert)
        }
    }
    
    // MARK: - API
    
    private func fetchAlerts() async {
        isLoading = true
        do {
            let fetchedAlerts: [GeofenceAlert] = try await SupabaseClientManager.shared.client.database
                .from("alerts")
                .select()
                .order("timestamp", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                self.alerts = fetchedAlerts
                self.isLoading = false
            }
        } catch {
            print("❌ Failed to alerts: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}

struct AlertRowView: View {
    let alert: GeofenceAlert
    
    var iconName: String {
        if alert.type.contains("entry") { return "arrow.right.to.line.circle.fill" }
        if alert.type.contains("exit") { return "arrow.left.to.line.circle.fill" }
        if alert.type.contains("violation") { return "exclamationmark.triangle.fill" }
        return "bell.circle.fill"
    }
    
    var iconColor: Color {
        if alert.type.contains("violation") { return .red }
        if alert.type.contains("entry") { return .green }
        if alert.type.contains("exit") { return .orange }
        return .blue
    }
    
    var timeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: alert.timestamp, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .padding(12)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(alert.message)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                Text(timeString)
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.top, 2)
            }
            
            Spacer()
            
            if !alert.isRead {
                Circle()
                    .fill(Color.appEmerald)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct AlertSegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.appEmerald : Color(white: 0.2))
                .foregroundColor(isSelected ? .black : .white)
                .cornerRadius(8)
        }
    }
}
    


