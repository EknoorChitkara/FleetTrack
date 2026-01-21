//
//  AlertDetailView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI
import Supabase

struct AlertDetailView: View {
    let alert: GeofenceAlert
    @Environment(\.dismiss) var dismiss
    @State private var fetchedTrip: Trip?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    messageSection
                    Spacer()
                    actionsSection
                }
                .padding()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Alert Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .accessibilityLabel("Close alert details")
                    .accessibilityIdentifier("alert_detail_close_button")
                }
            }
            .task {
                await fetchTripDetails()
            }
        }
    }
    
    private func fetchTripDetails() {
        guard let tripId = alert.tripId else {
            print("No tripId for this alert, skipping fetch.")
            return
        }
        
        Task {
            do {
                let trip: Trip = try await SupabaseClientManager.shared.client.database
                    .from("trips")
                    .select()
                    .eq("id", value: tripId.uuidString)
                    .single()
                    .execute()
                    .value
                
                await MainActor.run {
                    self.fetchedTrip = trip
                }
            } catch {
                print("Failed to fetch trip for alert: \(error)")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        HStack {
             Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            VStack(alignment: .leading) {
                Text(alert.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(alert.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(alert.title), received \(alert.timestamp.formatted(date: .abbreviated, time: .shortened))")
        .accessibilityIdentifier("alert_header_\(alert.id.uuidString.prefix(8))")
    }
    
    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alert Details")
                .font(.headline)
                .foregroundColor(.appEmerald)
            
            Text(alert.message)
                .font(.body)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Alert Message: \(alert.message)")
        .accessibilityIdentifier("alert_message_section")
    }
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                if let url = URL(string: "tel://1234567890") { // Placeholder
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Call Driver")
              }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .accessibilityLabel("Call Driver")
            .accessibilityHint("Starts a phone call to the driver")
            .accessibilityIdentifier("alert_detail_call_button")
            
            if alert.tripId != nil {
                if let trip = fetchedTrip {
                    NavigationLink(destination:
                        FleetManagerTripMapView(trip: FMTrip(
                            id: trip.id,
                            vehicleId: trip.vehicleId,
                            driverId: trip.driverId,
                            status: trip.status?.rawValue ?? "Unknown",
                            startAddress: trip.startAddress,
                            endAddress: trip.endAddress,
                            startTime: trip.startTime,
                            createdAt: trip.createdAt
                        ), showRoute: false)
                    ) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Track Driver")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appEmerald)
                        .cornerRadius(12)
                    }
                    .accessibilityLabel("Track Driver")
                    .accessibilityHint("Opens the map to track the current trip")
                    .accessibilityIdentifier("alert_detail_track_button")
                } else {
                     // Loading state for button
                     HStack {
                        ProgressView()
                        Text("Loading details...")
                    }
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }
}
