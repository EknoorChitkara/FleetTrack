//
//  TripMapView.swift
//  FleetTrack
//
//  Trip navigation and summary view:
//  - Scheduled: Navigate to Pickup
//  - In Progress: Navigate to Dropoff
//  - Completed: Show summary with route
//

import SwiftUI
import MapKit
import CoreLocation
import Combine
import Supabase

struct TripMapView: View {
    let trip: Trip
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationProvider = DeviceLocationProvider()
    @State private var routePolyline: MKPolyline?
    
    @State private var showArriveAlert = false
    @State private var showCompleteAlert = false
    @State private var estimatedTime: String?
    @State private var routeDistance: Double?
    @State private var isNavigating = false
    
    // Geofencing Manager
    @StateObject private var routeMonitor = RouteMonitoringManager.shared
    
    // Trip phases
    var isCompleted: Bool { trip.status == .completed }
    var isPickupPhase: Bool { trip.status == .scheduled }
    var isDeliveryPhase: Bool { trip.status == .ongoing }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map view
            UnifiedTripMap(
                trip: trip,
                provider: locationProvider,
                routePolyline: routePolyline,
                isOffRoute: routeMonitor.isOffRoute
            )
            .edgesIgnoringSafeArea(.all)
            
            // Bottom Card
            if isCompleted {
                completedBottomCard
            } else {
                activeBottomCard
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                statusBadge
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
        .alert("Start Trip?", isPresented: $showArriveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Start Trip") { startDelivery() }
        } message: {
            Text("Confirm you've picked up the package and ready to deliver?")
        }
        .alert("End Trip?", isPresented: $showCompleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("End Trip") { completeTrip() }
        } message: {
            Text("Confirm delivery to \(trip.endAddress ?? "destination")?")
        }
        .onAppear {
            if !isCompleted {
                locationProvider.startTracking()
            }
            // Initial route calculation
            calculateRoute()
        }
        .onDisappear {
            locationProvider.stopTracking()
        }
        .onChange(of: locationProvider.currentLocation) { newLoc in
            // Recalculate if needed (throttling logic can go here or in service)
             if let loc = newLoc, !isCompleted {
                 calculateRoute(from: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude))
             }
        }
    }
    
    private func calculateRoute(from userLoc: CLLocationCoordinate2D? = nil) {
        let start: CLLocationCoordinate2D
        let end: CLLocationCoordinate2D
        
        if let userLoc = userLoc {
            start = userLoc
        } else if let lat = trip.startLat, let lon = trip.startLong {
            start = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            return
        }
        
        if isPickupPhase {
            guard let lat = trip.startLat, let lon = trip.startLong else { return }
            end = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            guard let lat = trip.endLat, let lon = trip.endLong else { return }
            end = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        
        Task {
            do {
                let result = try await RouteCalculationService.shared.calculateRoute(from: start, to: end)
                await MainActor.run {
                    self.routePolyline = result.polyline
                    self.routeDistance = result.distanceInKilometers
                    self.estimatedTime = result.formattedDuration
                }
            } catch {
                print("Route calculation failed: \(error)")
            }
        }
    }
    
    var navigationTitle: String {
        if isCompleted { return "Trip Summary" }
        if isPickupPhase { return "Go to Pickup" }
        return "Delivering"
    }
    
    // MARK: - Status Badge
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            if isNavigating && !isCompleted {
                Circle().fill(Color.green).frame(width: 8, height: 8)
            }
            Text(statusText)
                .font(.caption)
                .fontWeight(.bold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor)
        .cornerRadius(8)
    }
    
    var statusText: String {
        if isCompleted { return "COMPLETED" }
        if isPickupPhase { return "TO PICKUP" }
        return "DELIVERING"
    }
    
    var statusColor: Color {
        if isCompleted { return .green }
        if isPickupPhase { return .orange }
        return .blue
    }
    
    // MARK: - Completed Trip Bottom Card
    
    private var completedBottomCard: some View {
        VStack(spacing: 16) {
            // Completed badge
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Trip Completed")
                    .font(.headline)
                    .foregroundColor(.green)
                Spacer()
                if let dist = trip.distance {
                    Text(String(format: "%.1f km", dist))
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Route summary
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 12, height: 12)
                    Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 2, height: 40)
                    Circle().fill(Color.red).frame(width: 12, height: 12)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PICKUP")
                            .font(.caption2).fontWeight(.bold).foregroundColor(.green)
                        Text(trip.startAddress ?? "Not specified")
                            .font(.subheadline)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DROPOFF")
                            .font(.caption2).fontWeight(.bold).foregroundColor(.red)
                        Text(trip.endAddress ?? "Not specified")
                            .font(.subheadline)
                    }
                }
                
                Spacer()
            }
            
            // Trip details
            if let startTime = trip.startTime, let endTime = trip.endTime {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Started").font(.caption).foregroundColor(.secondary)
                        Text(startTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Completed").font(.caption).foregroundColor(.secondary)
                        Text(endTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
    
    // MARK: - Active Trip Bottom Card
    
    private var activeBottomCard: some View {
        VStack(spacing: 12) {
            // Navigation status
            if isNavigating {
                HStack {
                    Image(systemName: "location.fill").foregroundColor(.blue)
                    Text("Navigating...").font(.subheadline).fontWeight(.medium)
                    Spacer()
                    if let time = estimatedTime {
                        Text(time).font(.headline).foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            
            // Route Deviation Warning
            if routeMonitor.isOffRoute {
                 HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.white)
                    Text("Off Route Alert!").fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    Text("\(Int(routeMonitor.currentDistanceFromRoute))m deviation").foregroundColor(.white)
                }
                .padding()
                .background(Color.red)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            // Destination Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isPickupPhase ? "PICKUP" : "DROPOFF")
                        .font(.caption2).fontWeight(.bold)
                        .foregroundColor(isPickupPhase ? .green : .red)
                    Text(isPickupPhase ? (trip.startAddress ?? "Pickup") : (trip.endAddress ?? "Dropoff"))
                        .font(.headline).lineLimit(2)
                }
                
                Spacer()
                
                if let dist = routeDistance {
                    VStack(alignment: .trailing) {
                        Text(String(format: "%.1f", dist)).font(.title2).fontWeight(.bold)
                        Text("km away").font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            
            // Route Overview
            HStack(spacing: 6) {
                Circle().fill(Color.green).frame(width: 8, height: 8)
                Text(trip.startAddress ?? "Pickup").font(.caption).lineLimit(1)
                Image(systemName: "arrow.right").font(.caption2).foregroundColor(.secondary)
                Circle().fill(Color.red).frame(width: 8, height: 8)
                Text(trip.endAddress ?? "Dropoff").font(.caption).lineLimit(1)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            Divider()
            
            // Action Buttons
            if isPickupPhase {
                Button { showArriveAlert = true } label: {
                    Label("Start Trip", systemImage: "play.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            } else if isDeliveryPhase {
                Button { showCompleteAlert = true } label: {
                    Label("End Trip", systemImage: "stop.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding()
    }
    
    // MARK: - Actions
    
    private func openMapsNavigation(to lat: Double?, lon: Double?, name: String) {
        guard let lat = lat, let lon = lon else { return }
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coord))
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    private func startDelivery() {
        Task {
            // 1. Update Trip Status
            try? await supabase.from("trips")
                .update(["status": "In Progress", "start_time": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: trip.id).execute()
            
            // 2. Start Geofencing
            if let startLat = trip.startLat, let startLong = trip.startLong,
               let endLat = trip.endLat, let endLong = trip.endLong {
                
                let start = CLLocationCoordinate2D(latitude: startLat, longitude: startLong)
                let end = CLLocationCoordinate2D(latitude: endLat, longitude: endLong)
                
                do {
                    print("📍 Fetching route for geofencing...")
                    let mkRoute = try await RouteService.shared.fetchRoute(from: start, to: end)
                    
                    let geofenceRoute = try RouteService.shared.createGeofenceRoute(
                        from: mkRoute,
                        routeId: trip.id,
                        start: start,
                        end: end,
                        corridorRadius: 100 // 100 meter corridor
                    )
                    
                    await MainActor.run {
                        RouteMonitoringManager.shared.startMonitoring(route: geofenceRoute)
                        dismiss()
                    }
                    
                } catch {
                    print("❌ Failed to start route monitoring: \(error)")
                     await MainActor.run { dismiss() }
                }
            } else {
                 await MainActor.run { dismiss() }
            }
        }
    }
    
    private func completeTrip() {
        // Stop Geofencing
        RouteMonitoringManager.shared.stopMonitoring()
        
        Task {
            try? await supabase.from("trips")
                .update(["status": "Completed", "end_time": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: trip.id).execute()
            await MainActor.run { dismiss() }
        }
    }
}

    // MARK: - Completed Trip Map (Static)
    // Deprecated: Replaced by UnifiedTripMap
    
    // MARK: - Driver Location Manager
    // Deprecated: Replaced by DeviceLocationProvider
    
    // MARK: - Live Trip Map
    // Deprecated: Replaced by UnifiedTripMap

#Preview {
    NavigationStack {
        TripMapView(trip: Trip.mockCompletedTrip)
    }
}
