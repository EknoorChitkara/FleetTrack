//
//  AllTripsView.swift
//  FleetTrack
//

import SwiftUI

struct AllTripsView: View {
    @EnvironmentObject var fleetVM: FleetViewModel
    @State private var selectedSegment = 0
    
    var currentTrips: [FMTrip] {
        fleetVM.trips.filter { trip in
            trip.status.lowercased() == "scheduled" || trip.status.lowercased() == "in progress"
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
            
            VStack(spacing: 24) {
                // Header
                HStack(spacing: 8) {
                    Text("Trips")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(fleetVM.trips.count)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.appEmerald)
                        .clipShape(Circle())
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Segment Control
                HStack(spacing: 12) {
                    TripSegmentButton(title: "Current (\(currentTrips.count))", isSelected: selectedSegment == 0) {
                        selectedSegment = 0
                    }
                    
                    TripSegmentButton(title: "Past (\(pastTrips.count))", isSelected: selectedSegment == 1) {
                        selectedSegment = 1
                    }
                }
                .padding(.horizontal)
                
                // Content
                if displayedTrips.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: selectedSegment == 0 ? "map" : "clock")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text(selectedSegment == 0 ? "No current trips" : "No past trips")
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
                        .padding(.bottom, 100) // Space for tab bar
                    }
                }
            }
        }
    }
}

struct TripSegmentButton: View {
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
