//
//  BasicMapView.swift
//  FleetTrack
//
//  Basic map view with current location
//  Phase 1: Display map with user location dot
//

import SwiftUI
import MapKit

struct BasicMapView: View {
    @StateObject private var mapVM = MapViewModel()
    
    var body: some View {
        ZStack {
            // Map
            Map(
                coordinateRegion: $mapVM.region,
                showsUserLocation: true,
                userTrackingMode: .constant(.none)
            )
            .ignoresSafeArea()
            
            // Controls overlay
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // Center on location button
                    Button(action: {
                        mapVM.centerOnCurrentLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.appEmerald)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .padding()
                }
            }
            
            // Loading indicator
            if mapVM.isLoadingLocation {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                    
                    Text("Getting your location...")
                        .foregroundColor(.white)
                        .padding(.top, 8)
                }
            }
            
            // Error message
            if let errorMessage = mapVM.errorMessage {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .padding()
                }
            }
        }
        .onAppear {
            // Request location permission and center on user
            mapVM.requestLocationAndCenter()
            
            // Start location updates
            mapVM.startLocationUpdates()
        }
        .onDisappear {
            // Stop location updates to save battery
            mapVM.stopLocationUpdates()
        }
    }
}

// MARK: - Preview

struct BasicMapView_Previews: PreviewProvider {
    static var previews: some View {
        BasicMapView()
    }
}
