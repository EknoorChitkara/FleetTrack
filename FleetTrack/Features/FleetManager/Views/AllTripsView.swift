//
//  AllTripsView.swift
//  FleetTrack
//

import SwiftUI

struct AllTripsView: View {
    @EnvironmentObject var fleetVM: FleetViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Text("All Trips")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding()
                
                if fleetVM.trips.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No trips recorded yet")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(fleetVM.trips.sorted(by: { ($0.startTime ?? Date.distantPast) > ($1.startTime ?? Date.distantPast) })) { trip in
                                TripRow(trip: trip)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}
