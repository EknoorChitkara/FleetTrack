//
//  FleetManagerTripsView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct FleetManagerTripsView: View {
    @EnvironmentObject var fleetVM: FleetViewModel
    @State private var selectedSegment = 0
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Trips")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Segmented Control
                Picker("Trip Type", selection: $selectedSegment) {
                    Text("Active").tag(0)
                    Text("Past").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 16)
                
                // Content
                if selectedSegment == 0 {
                    activeTripsView
                } else {
                    pastTripsView
                }
                
                Spacer(minLength: 120) // Bottom spacing for tab bar
            }
        }
    }
    
    var activeTripsView: some View {
        Group {
            if activeTrips.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "map.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No active trips")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    Text("Active trips will appear here")
                        .font(.system(size: 14))
                        .foregroundColor(.appSecondaryText)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(activeTrips) { trip in
                            TripRow(trip: trip)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    var pastTripsView: some View {
        Group {
            if pastTrips.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "map.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No past trips")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    Text("Completed trips will appear here")
                        .font(.system(size: 14))
                        .foregroundColor(.appSecondaryText)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(pastTrips) { trip in
                            TripRow(trip: trip)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // Helper computed properties to filter trips
    var activeTrips: [FMTrip] {
        fleetVM.trips.filter { trip in
            trip.status.lowercased() == "scheduled" || 
            trip.status.lowercased() == "ongoing" ||
            trip.status.lowercased() == "active"
        }
        .sorted { ($0.startTime ?? Date.distantPast) > ($1.startTime ?? Date.distantPast) }
    }
    
    var pastTrips: [FMTrip] {
        fleetVM.trips.filter { trip in
            trip.status.lowercased() == "completed" || 
            trip.status.lowercased() == "cancelled"
        }
        .sorted { ($0.startTime ?? Date.distantPast) > ($1.startTime ?? Date.distantPast) }
    }
}
