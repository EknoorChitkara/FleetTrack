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
    @State private var scoredRoutes: [ScoredRoute] = []
    @State private var selectedRouteID: UUID? // Selection State
    @State private var routePolyline: MKPolyline? // Legacy/Fallback support
    @State private var plannedRoutePolyline: MKPolyline? // Static Planned Route
    
    @State private var showArriveAlert = false
    @State private var showCompleteAlert = false
    @State private var showStartLog = false
    @State private var showEndLog = false
    @State private var showingInspectionSheet = false
    @State private var hasCompletedInspection = false
    
    // Log variables
    @State private var logOdometer: String = ""
    @State private var logFuel: Double = 0.5
    @State private var estimatedTime: String?
    @State private var routeDistance: Double?
    @State private var isNavigating = false
    
    @StateObject private var routeMonitor = RouteMonitoringManager.shared
    
    @State private var localTripStatus: TripStatus?
    
    // Alert Details
    let driverName: String
    let vehicleInfo: String
    
    // Trip phases
    var isCompleted: Bool { (localTripStatus ?? trip.status) == .completed }
    var isPickupPhase: Bool { (localTripStatus ?? trip.status) == .scheduled }
    var isDeliveryPhase: Bool { (localTripStatus ?? trip.status) == .ongoing }
    
    init(trip: Trip, driverName: String = "Unknown Driver", vehicleInfo: String = "Unknown Vehicle") {
        self.trip = trip
        self.driverName = driverName
        self.vehicleInfo = vehicleInfo
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map view
            UnifiedTripMap(
                trip: trip,
                provider: locationProvider,
                scoredRoutes: scoredRoutes,
                selectedRouteID: $selectedRouteID,
                plannedPolyline: plannedRoutePolyline,
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
        .sheet(isPresented: $showStartLog) {
            TripLogSheet(
                title: "Start Trip",
                subtitle: "Please log the vehicle status to start delivery",
                buttonTitle: "Confirm & Start",
                buttonColor: .green,
                odometer: $logOdometer,
                fuelLevel: $logFuel,
                onCommit: { startDelivery() }
            )
        }
        .sheet(isPresented: $showEndLog) {
            TripLogSheet(
                title: "End Trip",
                subtitle: "Final vehicle status after delivery",
                buttonTitle: "Complete Trip",
                buttonColor: .red,
                odometer: $logOdometer,
                fuelLevel: $logFuel,
                onCommit: { completeTrip() }
            )
        }
        .sheet(isPresented: $showingInspectionSheet) {
            DriverVehicleInspectionView(viewModel: VehicleInspectionViewModel(vehicle: nil)) // We need to pass vehicle if possible, but VM handles basic checks
        }
        .onAppear {
            if localTripStatus == nil {
                localTripStatus = trip.status
            }
            if !isCompleted {
                locationProvider.startTracking()
            }
            
            // 1. Calculate the Static Plan (Start -> End)
            calculatePlannedRoute()
            
            // 2. Calculate the Active Routes (Current -> End)
            // If location is not yet available, this might wait for onChange
            if let loc = locationProvider.currentLocation {
                calculateDetailedRoutes(from: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude))
            } else {
                // Try estimating from start if no location yet, but ideally wait
                // calculateDetailedRoutes(from: ...) 
            }
            
            checkDailyInspection()
        }
        .onDisappear {
            locationProvider.stopTracking()
        }
        .onChange(of: locationProvider.currentLocation) { newLoc in
            // Recalculate if needed (throttling logic can go here or in service)
             if let loc = newLoc, !isCompleted {
                 calculateDetailedRoutes(from: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude))
             }
        }
    }
    
    // Calculates the static "Official" path from Trip Start to Trip End
    private func calculatePlannedRoute() {
        guard let startLat = trip.startLat, let startLon = trip.startLong,
              let endLat = trip.endLat, let endLon = trip.endLong else { return }
        
        let start = CLLocationCoordinate2D(latitude: startLat, longitude: startLon)
        let end = CLLocationCoordinate2D(latitude: endLat, longitude: endLon)
        
        Task {
            do {
                let result = try await RouteCalculationService.shared.calculateRoute(from: start, to: end)
                await MainActor.run {
                    self.plannedRoutePolyline = result.polyline
                }
            } catch {
                print("⚠️ Failed to calculate planned route: \(error)")
            }
        }
    }
    
    // Calculates dynamic routes from User/Current Location to Destination
    private func calculateDetailedRoutes(from userLoc: CLLocationCoordinate2D) {
        var end: CLLocationCoordinate2D
        
        if isPickupPhase {
            guard let lat = trip.startLat, let lon = trip.startLong else { return }
            let pickupLoc = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            
            // Smart Switch: If user is ALREADY at/near pickup (< 300m), show route to Dropoff
            // allowing them to preview the main trip.
            let userLocation = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
            let pickupLocation = CLLocation(latitude: lat, longitude: lon)
            let distanceInMeters = userLocation.distance(from: pickupLocation)
            
            if distanceInMeters < 300 {
                print("📍 User is near pickup (\(Int(distanceInMeters))m). showing route to Dropoff.")
                guard let dLat = trip.endLat, let dLon = trip.endLong else { return }
                end = CLLocationCoordinate2D(latitude: dLat, longitude: dLon)
            } else {
                end = pickupLoc
            }
        } else {
            // Delivery phase or completed (default to drops off)
            guard let lat = trip.endLat, let lon = trip.endLong else { return }
            end = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        
        Task {
            do {
                print("🗺️ calculating dynamic routes: \(userLoc.latitude),\(userLoc.longitude) -> \(end.latitude),\(end.longitude)")
                
                // AI-Powered Route Selection
                let scoredResults = try await RouteRecommendationEngine.shared.findBestRoutes(from: userLoc, to: end)
                
                await MainActor.run {
                    self.updateRouteSelection(with: scoredResults)
                }
            } catch {
                print("⚠️ Dynamic route calculation failed: \(error)")
                // Note: We don't fallback to static route here because we have `plannedRoutePolyline` visible anyway.
            }
        }
    }
    
    private func updateRouteSelection(with routes: [ScoredRoute]) {
        self.scoredRoutes = routes
        // Auto-select recommended for display properties if needed
        if let recommended = routes.first(where: { $0.isRecommended }) {
            self.routePolyline = recommended.polyline
            self.routeDistance = recommended.distance / 1000.0
            self.estimatedTime = formatTime(seconds: recommended.expectedTravelTime)
            
            // Log for debugging
            print("🏆 AI Recommended: \(recommended.routeType.rawValue) (Score: \(recommended.score))")
            print("   - Fuel: \(recommended.fuelEstimate.liters)L")
            print("   - Traffic Factor: \(recommended.fuelEstimate.trafficFactor)")
        } else if let first = routes.first {
             // Fallback
             self.routePolyline = first.polyline
             self.routeDistance = first.distance / 1000.0
             self.estimatedTime = formatTime(seconds: first.expectedTravelTime)
        }
    }
    
    private func formatTime(seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
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
    

    
    // Helper accessors
    var selectedRoute: ScoredRoute? {
        guard let id = selectedRouteID else { return nil }
        return scoredRoutes.first(where: { $0.id == id })
    }
    
    var recommendedRoute: ScoredRoute? {
        scoredRoutes.first(where: { $0.isRecommended })
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
            
            // AI Recommendation / Selection Banner
            if let displayRoute = selectedRoute ?? recommendedRoute {
                HStack {
                    Image(systemName: displayRoute.isRecommended ? "sparkles" : "map.fill")
                    VStack(alignment: .leading) {
                        Text(displayRoute.isRecommended ? "AI Recommended: \(displayRoute.routeType.rawValue)" : "Selected: \(displayRoute.routeType.rawValue)")
                            .fontWeight(.bold)
                            .font(.subheadline)
                        
                        // Show comparative stats
                        Text("~\(Int(displayRoute.fuelEstimate.liters))L Fuel • \(formatTime(seconds: displayRoute.expectedTravelTime))")
                            .font(.caption)
                            .opacity(0.9)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.9)) // Match Map Route Color
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 4)
            }
            
            // Navigation status
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
                Button(action: {
                    if hasCompletedInspection {
                        logOdometer = ""
                        logFuel = 0.5 // Reset fuel to default for start log
                        showStartLog = true
                    } else {
                        showingInspectionSheet = true
                    }
                }) {
                    Text(hasCompletedInspection ? "Start Trip" : "Pending Inspection")
                        .font(.headline)
                        .foregroundColor(.white) // Changed to white for better contrast
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(hasCompletedInspection ? Color.green : Color.orange) // Assuming Color.appEmerald is Color.green
                        .cornerRadius(12)
                }
            } else if isDeliveryPhase {
                Button { 
                    logOdometer = ""
                    logFuel = 0.5 // Reset fuel to default for end log
                    showEndLog = true 
                } label: {
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
    
    @State private var isProcessing = false

    private func startDelivery() {
        guard !isProcessing else { return }
        isProcessing = true
        
        Task {
            // 1. Update Trip Status & Logs
            let updateData: [String: AnyEncodable] = [
                "status": AnyEncodable("In Progress"),
                "start_time": AnyEncodable(ISO8601DateFormatter().string(from: Date())),
                "start_odometer": AnyEncodable(Double(logOdometer) ?? 0.0),
                "start_fuel_level": AnyEncodable(logFuel)
            ]
            
            do {
                try await supabase.from("trips")
                    .update(updateData)
                    .eq("id", value: trip.id.uuidString).execute()
            } catch {
                print("❌ Failed to update start trip: \(error)")
            }
            
            // 2. Start Geofencing
            if let startLat = trip.startLat, let startLong = trip.startLong,
               let endLat = trip.endLat, let endLong = trip.endLong {
                
                let start = CLLocationCoordinate2D(latitude: startLat, longitude: startLong)
                let end = CLLocationCoordinate2D(latitude: endLat, longitude: endLong)
                
                do {
                    print("📍 Fetching route for geofencing...")
                    print("   - Start: \(start.latitude), \(start.longitude)")
                    print("   - End: \(end.latitude), \(end.longitude)")
                    let mkRoute = try await RouteService.shared.fetchRoute(from: start, to: end)
                    
                    let geofenceRoute = try RouteService.shared.createGeofenceRoute(
                        from: mkRoute,
                        routeId: trip.id,
                        start: start,
                        end: end,
                        corridorRadius: 100 // 100 meter corridor
                    )
                    
                    await RouteMonitoringManager.shared.startMonitoring(
                        route: geofenceRoute,
                        driverName: self.driverName,
                        vehicleInfo: self.vehicleInfo
                    )
                    
                    await MainActor.run {
                        // 3. Update local state instead of dismissing
                        self.localTripStatus = .ongoing
                        self.isProcessing = false
                        
                        // Recalculate route for navigation (from current location to DROP OFF)
                        if let loc = self.locationProvider.currentLocation {
                            self.calculateDetailedRoutes(from: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude))
                        }
                    }
                    
                } catch {
                    print("❌ Failed to start route monitoring: \(error)")
                    await MainActor.run { 
                        isProcessing = false
                    }
                }
            } else {
                 await MainActor.run { 
                    self.localTripStatus = .ongoing
                    self.isProcessing = false
                    // Fallback calc
                    if let loc = self.locationProvider.currentLocation {
                        self.calculateDetailedRoutes(from: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude))
                    }
                 }
            }
        }
    }
    
    private func completeTrip() {
        // Stop Geofencing
        RouteMonitoringManager.shared.stopMonitoring()
        
        Task {
            let updateData: [String: AnyEncodable] = [
                "status": AnyEncodable("Completed"),
                "end_time": AnyEncodable(ISO8601DateFormatter().string(from: Date())),
                "end_odometer": AnyEncodable(Double(logOdometer) ?? 0.0),
                "end_fuel_level": AnyEncodable(logFuel)
            ]
            
            do {
                try await supabase.from("trips")
                    .update(updateData)
                    .eq("id", value: trip.id.uuidString).execute()
                await MainActor.run { dismiss() }
            } catch {
                print("❌ Failed to update end trip: \(error)")
                await MainActor.run { isProcessing = false }
            }
        }
    }
    
    private func checkDailyInspection() {
         Task {
             do {
                  let startOfDay = Calendar.current.startOfDay(for: Date())
                  let startString = ISO8601DateFormatter().string(from: startOfDay)
                  
                  let count = try await supabase
                      .from("vehicle_inspections")
                      .select("id", head: true, count: .exact)
                      .eq("vehicle_id", value: trip.vehicleId)
                      .gte("created_at", value: startString)
                      .execute()
                      .count
                  
                  await MainActor.run {
                      hasCompletedInspection = (count ?? 0) > 0
                  }
             } catch {
                 print("⚠️ Failed to check inspection status: \(error)")
                 // Allow trip if check fails to prevent blocking
                 await MainActor.run { hasCompletedInspection = true } 
             }
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
        TripMapView(
            trip: Trip.mockCompletedTrip,
            driverName: "Mock Driver",
            vehicleInfo: "Toyota Prious (MH-12-AB-1234)"
        )
    }
}
