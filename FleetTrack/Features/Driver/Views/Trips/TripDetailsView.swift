//
//  TripDetailsView.swift
//  FleetTrack
//
//  Created for Driver
//

import SwiftUI
import MapKit

struct TripDetailsView: View {
    let trip: Trip
    @ObservedObject var viewModel: DriverTripsViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedRouteId: UUID?
    
    // Mock Map Region
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

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
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // FleetTrack Logo Text
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.0, green: 0.85, blue: 0.4)) // Bright Green
                                .frame(width: 32, height: 32)
                            Image(systemName: "truck.box.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                        }
                        
                        Text("FleetTrack")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    Button {
                        // Profile action placeholder
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Map View
                        if let startLat = trip.startLat, let startLong = trip.startLong,
                           let endLat = trip.endLat, let endLong = trip.endLong {
                            
                            MapView(
                                startCoordinate: CLLocationCoordinate2D(latitude: startLat, longitude: startLong),
                                endCoordinate: CLLocationCoordinate2D(latitude: endLat, longitude: endLong)
                            )
                            .frame(height: 300)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        } else {
                            // Fallback if coordinates missing
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 300)
                                .cornerRadius(16)
                                .overlay(
                                    Text("Map not available")
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        // Route Overview
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Route Overview")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Pickup
                            HStack(alignment: .top) {
                                Circle().fill(Color.appEmerald).frame(width: 10, height: 10).padding(.top, 4)
                                VStack(alignment: .leading) {
                                    Text("Pickup Location")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(trip.pickupLocationName ?? trip.startAddress ?? "Unknown")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.leading, 8)
                            }
                            
                            // Dropoff
                            HStack(alignment: .top) {
                                Circle().fill(Color.red).frame(width: 10, height: 10).padding(.top, 4)
                                VStack(alignment: .leading) {
                                    Text("Drop-off Location")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(trip.dropoffLocationName ?? trip.endAddress ?? "Unknown")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.leading, 8)
                            }
                            
                            Divider().background(Color.gray.opacity(0.3))
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Scheduled Time")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(trip.startTime?.formatted(date: .omitted, time: .shortened) ?? "TBD")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Distance")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(trip.formattedDistance ?? "--")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            if let notes = trip.notes {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Notes")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(notes)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(16)
                        
                        // Route Suggestions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Route Suggestions")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Mock suggestions if empty
                            let suggestions = trip.routeSuggestions.isEmpty ? 
                                [
                                    RouteSuggestion(name: "Fastest", duration: 900, distance: 18, tag: .standard),
                                    RouteSuggestion(name: "Fuel Saver", duration: 1320, distance: 16, tag: .low),
                                    RouteSuggestion(name: "Balanced", duration: 1080, distance: 17, tag: .optimal, isRecommended: true)
                                ] : trip.routeSuggestions
                            
                            ForEach(suggestions) { route in
                                RouteSuggestionRow(
                                    suggestion: route,
                                    isSelected: selectedRouteId == route.id || (selectedRouteId == nil && route.isRecommended)
                                ) {
                                    selectedRouteId = route.id
                                    viewModel.selectedRouteId = route.id
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // Start Trip Button
                Button(action: {
                    var tripToStart = trip
                    tripToStart.routeSuggestions = trip.routeSuggestions.isEmpty ? [
                        RouteSuggestion(name: "Fastest", duration: 900, distance: 18, tag: .standard),
                        RouteSuggestion(name: "Fuel Saver", duration: 1320, distance: 16, tag: .low),
                        RouteSuggestion(name: "Balanced", duration: 1080, distance: 17, tag: .optimal, isRecommended: true)
                    ] : trip.routeSuggestions
                    viewModel.startTrip(tripToStart)
                }) {
                    Text("Start Trip")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.0, green: 0.85, blue: 0.4)) // Bright Green
                        .cornerRadius(12)
                }
                .padding()
                .background(Color.appBackground)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if let recommended = trip.routeSuggestions.first(where: { $0.isRecommended }) {
                selectedRouteId = recommended.id
            }
        }
    }
}

struct RouteSuggestionRow: View {
    let suggestion: RouteSuggestion
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
             HStack {
                 // Radio indicator
                 ZStack {
                     Circle()
                         .stroke(isSelected ? Color.appEmerald : Color.gray, lineWidth: 2)
                         .frame(width: 20, height: 20)
                     if isSelected {
                         Circle()
                             .fill(Color.appEmerald)
                             .frame(width: 10, height: 10)
                     }
                 }
                 
                 VStack(alignment: .leading, spacing: 4) {
                     HStack {
                         Text(suggestion.name)
                             .font(.system(size: 16, weight: .semibold))
                             .foregroundColor(.white)
                         
                         if suggestion.isRecommended {
                             Text("AI Recommended")
                                 .font(.caption2)
                                 .fontWeight(.bold)
                                 .padding(.horizontal, 6)
                                 .padding(.vertical, 2)
                                 .background(Color.appEmerald.opacity(0.2))
                                 .foregroundColor(.appEmerald)
                                 .cornerRadius(4)
                         }
                     }
                     
                     HStack(spacing: 12) {
                         Label(suggestion.formattedDuration, systemImage: "clock")
                             .font(.caption)
                             .foregroundColor(.gray)
                         
                         Text("\(Int(suggestion.distance)) km")
                             .font(.caption)
                             .foregroundColor(.gray)
                         
                         if let tag = suggestion.tag {
                             Label(tag.rawValue, systemImage: tag == .low ? "leaf" : "speedometer")
                                 .font(.caption)
                                 .foregroundColor(.gray)
                         }
                     }
                 }
                 .padding(.leading, 8)
                 
                 Spacer()
             }
             .padding()
             .background(Color.white.opacity(0.05))
             .cornerRadius(12)
             .overlay(
                 RoundedRectangle(cornerRadius: 12)
                     .stroke(isSelected ? Color.appEmerald : Color.clear, lineWidth: 1)
             )
        }
    }
}
