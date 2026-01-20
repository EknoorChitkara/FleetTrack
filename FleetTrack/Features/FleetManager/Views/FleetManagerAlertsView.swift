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
    


