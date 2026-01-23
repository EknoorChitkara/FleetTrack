//
//  AllTripsView.swift
//  FleetTrack
//

import SwiftUI

struct AllTripsView: View {
    @EnvironmentObject var fleetVM: FleetViewModel
    @State private var selectedSegment = 0
    @State private var showPlanTrip = false
    
    var currentTrips: [FMTrip] {
        fleetVM.trips.filter { trip in
            trip.status.lowercased() == "scheduled" || trip.status.lowercased() == "ongoing" || trip.status.lowercased() == "in progress"
        }
    }
    
    var pastTrips: [FMTrip] {
        fleetVM.trips.filter { trip in
            trip.status.lowercased() == "completed" || trip.status.lowercased() == "cancelled"
        }
    }
    
    var displayedTrips: [FMTrip] {
        selectedSegment == 0 ? currentTrips : pastTrips
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trips")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(fleetVM.trips.count) Total Shipments")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showPlanTrip = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.appEmerald)
                    }
                    .accessibilityLabel("Plan New Trip")
                    .accessibilityIdentifier("all_trips_add_button")
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Segment Control
                HStack(spacing: 0) {
                    TripSegmentButton(title: "Active", count: currentTrips.count, isSelected: selectedSegment == 0) {
                        withAnimation(.spring()) {
                            selectedSegment = 0
                        }
                    }
                    
                    TripSegmentButton(title: "History", count: pastTrips.count, isSelected: selectedSegment == 1) {
                        withAnimation(.spring()) {
                            selectedSegment = 1
                        }
                    }
                }
                .padding(4)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // Content
                if displayedTrips.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: selectedSegment == 0 ? "map.fill" : "clock.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.3))
                        
                        Text(selectedSegment == 0 ? "No active trips" : "No trip history")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(displayedTrips.sorted(by: { ($0.startTime ?? Date.distantPast) > ($1.startTime ?? Date.distantPast) })) { trip in
                                NavigationLink(destination: FleetManagerTripMapView(trip: trip)) {
                                    TripRow(trip: trip)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                        .padding(.bottom, 100)
                    }
                }
            }
        }

        .onAppear {
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                 InAppVoiceManager.shared.speak(voiceSummary())
             }
        }
        .onChange(of: selectedSegment) { oldValue, newValue in
            InAppVoiceManager.shared.speak(voiceSummary())
        }
        .sheet(isPresented: $showPlanTrip) {
            PlanTripView().environmentObject(fleetVM)
        }
    }
}

// MARK: - InAppVoiceReadable
extension AllTripsView: InAppVoiceReadable {
    func voiceSummary() -> String {
        let segmentName = selectedSegment == 0 ? "Current" : "Past"
        let count = displayedTrips.count
        
        var summary = "\(segmentName) Trips List. "
        
        if count == 0 {
             summary += "No \(segmentName.lowercased()) trips found."
        } else {
            summary += "Showing \(count) trips. "
            if selectedSegment == 0 {
                summary += "Includes scheduled and ongoing trips. "
            } else {
                summary += "Includes completed and cancelled trips. "
            }
        }
        
        return summary
    }
}

struct TripSegmentButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .fontWeight(isSelected ? .bold : .medium)
                Text("(\(count))")
                    .font(.caption)
                    .opacity(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.appEmerald : Color.clear)
            .foregroundColor(isSelected ? .black : .gray)
            .cornerRadius(8)
        }
        .accessibilityLabel("\(title), \(count) trips")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier("trip_segment_\(title.lowercased())")
    }
}
