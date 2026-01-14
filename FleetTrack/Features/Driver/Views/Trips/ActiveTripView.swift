//
//  ActiveTripView.swift
//  FleetTrack
//
//  Created for Driver
//

import SwiftUI
import MapKit

struct ActiveTripView: View {
    let trip: Trip
    @ObservedObject var viewModel: DriverTripsViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Timer for elapsed time mock
    @State private var elapsedTime = "24 min"
    @State private var distanceCovered = "12.4 km"
    @State private var eta = "8 min"
    
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
                    
                    // Live Status Badge
                    Text("LIVE")
                        .font(.caption2)
                        .fontWeight(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .padding(.leading, 4)
                    
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
                .background(Color.appCardBackground)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Map View
                        if let startLat = trip.startLat, let startLong = trip.startLong,
                           let endLat = trip.endLat, let endLong = trip.endLong {
                            
                            MapView(
                                startCoordinate: CLLocationCoordinate2D(latitude: startLat, longitude: startLong),
                                endCoordinate: CLLocationCoordinate2D(latitude: endLat, longitude: endLong)
                            )
                            .frame(height: 250)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        
                        // Live Metrics
                        VStack(spacing: 16) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Live Metrics")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            
                            HStack {
                                MetricItem(label: "Elapsed Time", value: elapsedTime)
                                Spacer()
                                MetricItem(label: "Distance Covered", value: distanceCovered)
                            }
                            
                            HStack {
                                MetricItem(label: "ETA", value: eta)
                                Spacer()
                                VStack(alignment: .leading) {
                                    Text("Status")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("On Time")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.appEmerald)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(16)
                        
                        // Route Suggestions (Collapsed/Compact view)
                        // Just showing selected strategy
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Active Strategy")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if let routeId = viewModel.selectedRouteId,
                               let route = trip.routeSuggestions.first(where: { $0.id == routeId }) {
                                RouteSuggestionRow(suggestion: route, isSelected: true, action: {})
                                    .disabled(true)
                            } else if let rec = trip.routeSuggestions.first(where: { $0.isRecommended }) {
                                // Fallback
                                RouteSuggestionRow(suggestion: rec, isSelected: true, action: {})
                                    .disabled(true)
                            }
                        }
                        .padding()
                        
                        // Voice Log Section
                        VStack(spacing: 20) {
                            HStack {
                                Text("Voice Log")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            
                            Button(action: {
                                withAnimation {
                                    viewModel.toggleRecording()
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(viewModel.isRecording ? Color.red.opacity(0.1) : Color.white.opacity(0.05))
                                        .frame(width: 80, height: 80)
                                    
                                    Circle()
                                        .fill(viewModel.isRecording ? Color.red : Color.white.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(viewModel.isRecording ? .white : .gray)
                                }
                            }
                            
                            Text(viewModel.isRecording ? "Scanning... \(Int(viewModel.recordingDuration))s" : "Tap to start recording")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if !viewModel.isRecording && !trip.voiceLogs.isEmpty {
                                // Show list of recorded logs
                                VStack(spacing: 8) {
                                    ForEach(trip.voiceLogs) { log in
                                        HStack {
                                            Image(systemName: "waveform")
                                                .foregroundColor(.appEmerald)
                                            Text("Voice Note \(log.createdAt.formatted(date: .omitted, time: .shortened))")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text("\(Int(log.duration))s")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                    }
                                }
                            } else if !viewModel.isRecording {
                                Text("No voice notes recorded yet")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(16)
                    }
                    .padding()
                }
                
                // Complete Trip Button
                Button(action: {
                    viewModel.completeTrip()
                }) {
                    Text("Complete Trip")
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
    }
}

struct MetricItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
