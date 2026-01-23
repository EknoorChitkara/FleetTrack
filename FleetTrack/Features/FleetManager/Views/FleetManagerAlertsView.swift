//
//  FleetManagerAlertsView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI
import Supabase

struct FleetManagerAlertsView: View {
    @State private var alerts: [GeofenceAlert] = []
    @State private var isLoading = false
    @State private var selectedAlert: GeofenceAlert?
    
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
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.red)
                            .clipShape(Capsule())
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
                        .accessibilityLabel("Refresh Alerts")
                        .accessibilityIdentifier("fleet_alerts_refresh_button")
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                if alerts.isEmpty {
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
                            ForEach(alerts) { alert in
                                AlertRowView(alert: alert)
                                    .onTapGesture {
                                        selectedAlert = alert
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .accessibilityIdentifier("fleet_alerts_list")
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
        .onAppear {
            InAppVoiceManager.shared.speak(voiceSummary())
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

// MARK: - InAppVoiceReadable Extension
extension FleetManagerAlertsView: InAppVoiceReadable {
    func voiceSummary() -> String {
        let unreadCount = alerts.filter({ !$0.isRead }).count
        var summary = "Fleet Alerts. "
        
        if unreadCount > 0 {
            summary += "You have \(unreadCount) unread alerts. "
            
            // Read first few unread alerts
            let unread = alerts.filter({ !$0.isRead }).prefix(3)
            for (index, alert) in unread.enumerated() {
                summary += "Alert \(index + 1): \(alert.title). \(alert.message). "
            }
        } else {
             summary += "No new alerts. "
             // Read most recent old alert
             if let recent = alerts.first {
                 summary += "Most recent: \(recent.title). "
             }
        }
        return summary
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(alert.isRead ? "Read" : "Unread") Alert. \(alert.title): \(alert.message). \(timeString)")
        .accessibilityHint(alert.isRead ? "Double tap to view details" : "Double tap to view and mark as read")
        .accessibilityIdentifier("fleet_alert_row_\(alert.id.uuidString.prefix(8))")
    }
}
    


