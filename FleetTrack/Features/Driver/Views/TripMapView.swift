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
import UIKit
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
    @State private var assignedVehicle: Vehicle? = nil
    @State private var showOdometerError = false
    @State private var odometerErrorMessage = ""
    @State private var startOdometerReading: Double = 0.0
    @State private var showFuelError = false
    @State private var showStartTripError = false
    @State private var startTripErrorMessage = ""
    @State private var showDistAlert = false
    @State private var routeLineColor: Color = .blue
    
    // Log Sheet Data
    @State private var odometerReading = ""
    @State private var fuelLevel = 50.0
    @State private var odometerPhoto: UIImage?
    @State private var fuelGaugePhoto: UIImage?
    @State private var selectedStartRouteIndex: Int?
    
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
    
    // Check if trip is scheduled for today
    var isScheduledForToday: Bool {
        guard let startTime = trip.startTime else { return true } // If no startTime, allow starting
        let calendar = Calendar.current
        let tripDay = calendar.startOfDay(for: startTime)
        let today = calendar.startOfDay(for: Date())
        return tripDay <= today
    }
    
    init(trip: Trip, driverName: String = "Unknown Driver", vehicleInfo: String = "Unknown Vehicle") {
        self.trip = trip
        self.driverName = driverName
        self.vehicleInfo = vehicleInfo
    }
    
    var body: some View {
        contentView
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showStartLog) {
                startTripSheet
            }
            .sheet(isPresented: $showEndLog) {
                endTripSheet
            }
            .fullScreenCover(isPresented: $showingInspectionSheet) {
                DriverVehicleInspectionView(viewModel: VehicleInspectionViewModel(vehicle: assignedVehicle))
            }
            .alert("Invalid Odometer Reading", isPresented: $showOdometerError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(odometerErrorMessage)
            }
            .alert("Empty Fuel Tank", isPresented: $showFuelError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Cannot start trip with empty fuel. Please refuel the vehicle before starting the trip.")
            }
            .alert("Start Trip Failed", isPresented: $showStartTripError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(startTripErrorMessage)
            }
            .alert("Trip Summary", isPresented: $showTripSummary) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(tripSummaryMessage)
            }
            .onAppear(perform: onAppearActions)
            .onDisappear {
                locationProvider.stopTracking()
            }
            .onChange(of: locationProvider.currentLocation) { newLoc in
                if let loc = newLoc, !isCompleted {
                    calculateDetailedRoutes(from: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude))
                }
            }
    }
    
    private var contentView: some View {
        ZStack(alignment: .bottom) {
            mapView
            bottomCardView
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Close") {
                dismiss()
            }
            .foregroundColor(.white)
            .accessibilityIdentifier("trip_map_close_button")
        }
        
        if !isCompleted && !isPickupPhase {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: RefuelView(viewModel: RefuelViewModel(tripId: trip.id, vehicleId: trip.vehicleId, driverId: trip.driverId))) {
                    Image(systemName: "fuelpump.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
            }
        }
    }
    
    private var startTripSheet: some View {
        TripLogSheet(
            title: "Start Trip",
            subtitle: "Please log the vehicle status to start delivery",
            buttonTitle: "Confirm & Start",
            buttonColor: .green,
            odometer: $odometerReading,
            fuelLevel: $fuelLevel,
            odometerUnscaledImage: $odometerPhoto,
            fuelGaugeUnscaledImage: $fuelGaugePhoto,
            availableRoutes: scoredRoutes.map { $0.routeType.rawValue },
            selectedRouteIndex: $selectedStartRouteIndex,
            onCommit: {
                startTrip()
            }
        )
        .interactiveDismissDisabled()
    }
    
    private var endTripSheet: some View {
        TripLogSheet(
            title: "Complete Trip",
            subtitle: "Please log final readings",
            buttonTitle: "Complete Trip",
            buttonColor: .blue,
            odometer: $odometerReading,
            fuelLevel: $fuelLevel,
            odometerUnscaledImage: $odometerPhoto,
            fuelGaugeUnscaledImage: $fuelGaugePhoto,
            selectedRouteIndex: .constant(nil),
            onCommit: {
                completeTrip()
            }
        )
    }
    
    private func onAppearActions() {
        if localTripStatus == nil {
            localTripStatus = trip.status
        }
        if !isCompleted {
            locationProvider.startTracking()
        }
        
        if let startOdo = trip.startOdometer {
            self.startOdometerReading = startOdo
        }
<<<<<<< HEAD
        .task {
            // Voice Narration Trigger
            // Wait slightly for routes to calculate if possible, but don't block too long
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            InAppVoiceManager.shared.speak(voiceSummary())
        }
=======
        
        calculatePlannedRoute()
        
        if let loc = locationProvider.currentLocation {
            calculateDetailedRoutes(from: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude))
        }
        
        checkDailyInspection()
        fetchVehicle()
>>>>>>> c0aa37f8061a50926f8f393d04472e18bd6d5893
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
    
     private func completeTrip() {
        guard let endOdo = Double(odometerReading),
              let odoPhoto = odometerPhoto,
              let gaugePhoto = fuelGaugePhoto else { return }
        
        Task {
            do {
                // 1. Upload Photos
                let time = Date().timeIntervalSince1970
                let odoPath = "trips/\(trip.id)/end_odo_\(time).jpg"
                let gaugePath = "trips/\(trip.id)/end_fuel_\(time).jpg"
                
                guard let odoData = odoPhoto.jpegData(compressionQuality: 0.7),
                      let gaugeData = gaugePhoto.jpegData(compressionQuality: 0.7) else { return }
                
                let odoUrl = try await TripService.shared.uploadTripPhoto(data: odoData, path: odoPath)
                let gaugeUrl = try await TripService.shared.uploadTripPhoto(data: gaugeData, path: gaugePath)

                // 2. Complete Trip
                try await TripService.shared.completeTrip(
                    tripId: trip.id,
                    endOdometer: endOdo,
                    endFuelLevel: fuelLevel,
                    odometerPhotoUrl: odoUrl,
                    gaugePhotoUrl: gaugeUrl,
                    actualDistance: routeDistance
                )
                
                localTripStatus = .completed
                isNavigating = false
                showTripSummary = true
                
                // Update vehicle efficiency
                if let distance = routeDistance, distance > 0 {
                     // 3. Fetch Refills for accurate calculation
                     let refills = try? await FuelTrackingService.shared.fetchTripRefills(tripId: trip.id)
                     
                     let consumed = FuelCalculationService.shared.calculateSensorBasedConsumption(
                        startPercentage: trip.startFuelLevel ?? 50,
                        endPercentage: fuelLevel,
                        tankCapacity: assignedVehicle?.tankCapacity ?? 60.0,
                        refills: refills ?? []
                     )
                     
                     if consumed > 0 {
                          let efficiency = distance / consumed
                          try? await FuelTrackingService.shared.updateVehicleEfficiency(
                             vehicleId: trip.vehicleId,
                             newEfficiency: efficiency
                          )
                     }
                }
                
            } catch {
                print("❌ Failed to complete trip: \(error)")
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Trip Status: \(statusText)")
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
    
    
    // MARK: - View Components
    
    private var mapView: some View {
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
    }
    
    private var bottomCardView: some View {
        Group {
            if isCompleted {
                completedBottomCard
            } else {
                activeBottomCard
            }
        }
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Route Recommendation: \(displayRoute.isRecommended ? "AI Recommended" : "Selected"). Fuel Estimate: \(Int(displayRoute.fuelEstimate.liters)) liters. Travel time: \(formatTime(seconds: displayRoute.expectedTravelTime))")
                .accessibilityIdentifier("trip_map_recommendation_banner")
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
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(isPickupPhase ? "Pickup" : "Dropoff") at \(isPickupPhase ? (trip.startAddress ?? "Pickup") : (trip.endAddress ?? "Dropoff")). Distance: \(routeDistance != nil ? String(format: "%.1f km away", routeDistance!) : "unknown distance")")
            
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
                    if !isScheduledForToday {
                        // Trip not scheduled for today - do nothing
                        return
                    }
                    if hasCompletedInspection {
                        odometerReading = ""
                        fuelLevel = 50.0 // Reset fuel to default for start log
                        showStartLog = true
                    } else {
                        showingInspectionSheet = true
                    }
                }) {
                    Text(!isScheduledForToday ? "Scheduled for Later" : (hasCompletedInspection ? "Start Trip" : "Pending Inspection"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(!isScheduledForToday ? Color.gray : (hasCompletedInspection ? Color.green : Color.orange))
                        .cornerRadius(12)
                }
                .disabled(!isScheduledForToday)
                .accessibilityIdentifier("trip_map_action_button")
            } else if isDeliveryPhase {
                Button {
                    // Prevent Ending logic
                    if let dist = routeDistance, dist > 0.5 { // Check if distance > 0.5km (500m)
                        showDistAlert = true
                    } else {
                        odometerReading = ""
                        fuelLevel = 50.0 // Reset fuel to default for end log
                        showEndLog = true
                    }
                } label: {
                    Label("End Trip", systemImage: "stop.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background((routeDistance ?? 0) > 5 ? Color.gray : Color.red)
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
        .alert("Too Far From Destination", isPresented: $showDistAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You are not at the destination yet. Please reach the destination to end the trip.")
        }
    }
    
    // MARK: - Actions
    
    private func openMapsNavigation(to lat: Double?, lon: Double?, name: String) {
        guard let lat = lat, let lon = lon else { return }
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let mapItem = MKMapItem(location: CLLocation(latitude: coord.latitude, longitude: coord.longitude), address: nil)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    @State private var isProcessing = false
    
    private func startTrip() {
        print("🟢 [StartTrip] Tapped start trip for tripId=\(trip.id)")
        if isProcessing { return }
        if (localTripStatus ?? trip.status) == .ongoing {
            print("ℹ️ [StartTrip] Trip already in progress, ignoring duplicate start.")
            return
        }
        guard let startOdo = Double(odometerReading) else {
            print("⚠️ [StartTrip] Invalid odometer input: \(odometerReading)")
            odometerErrorMessage = "Please enter a valid odometer reading."
            showOdometerError = true
            return
        }
        if startOdo < startOdometerReading {
            print("⚠️ [StartTrip] Odometer less than last recorded. startOdo=\(startOdo), last=\(startOdometerReading)")
            odometerErrorMessage = "Odometer reading cannot be less than the last recorded value (\(Int(startOdometerReading)) km)."
            showOdometerError = true
            return
        }
        if fuelLevel <= 0 {
            print("⚠️ [StartTrip] Fuel level is empty: \(fuelLevel)")
            showFuelError = true
            return
        }
        guard let odoPhoto = odometerPhoto,
              let gaugePhoto = fuelGaugePhoto else {
            print("⚠️ [StartTrip] Missing photos. odoPhoto=\(odometerPhoto != nil), gaugePhoto=\(fuelGaugePhoto != nil)")
            startTripErrorMessage = "Please capture both odometer and fuel gauge photos."
            showStartTripError = true
            return
        }
        
        isProcessing = true
        Task {
            defer { Task { @MainActor in isProcessing = false } }
            do {
                print("🟡 [StartTrip] Uploading photos to bucket=\(SupabaseConfig.tripPhotosBucket)")
                // 1. Upload Photos
                let time = Date().timeIntervalSince1970
                let odoPath = "trips/\(trip.id)/start_odo_\(time).jpg"
                let gaugePath = "trips/\(trip.id)/start_fuel_\(time).jpg"
                print("🟡 [StartTrip] Upload paths odo=\(odoPath) gauge=\(gaugePath)")
                
                guard let odoData = odoPhoto.jpegData(compressionQuality: 0.7),
                      let gaugeData = gaugePhoto.jpegData(compressionQuality: 0.7) else { return }
                
                let odoUrl = try await TripService.shared.uploadTripPhoto(data: odoData, path: odoPath)
                let gaugeUrl = try await TripService.shared.uploadTripPhoto(data: gaugeData, path: gaugePath)
                print("✅ [StartTrip] Uploaded photos. odoUrl=\(odoUrl), gaugeUrl=\(gaugeUrl)")
                
                // 2. Start Trip
                print("🟡 [StartTrip] Updating trip status to In Progress")
                try await TripService.shared.startTrip(
                    tripId: trip.id,
                    startOdometer: startOdo,
                    startFuelLevel: fuelLevel,
                    odometerPhotoUrl: odoUrl,
                    gaugePhotoUrl: gaugeUrl,
                    routeIndex: selectedStartRouteIndex
                )
                print("✅ [StartTrip] Trip started successfully")
                
                await MainActor.run {
                    localTripStatus = .ongoing
                    isNavigating = true
                }
                
                // Switch to selected route if provided
                if let index = selectedStartRouteIndex, index < scoredRoutes.count {
                     let route = scoredRoutes[index]
                     selectedRouteID = route.id
                }
                
                // Calculate route from current location
                let currentCoord: CLLocationCoordinate2D
                if let loc = locationProvider.currentLocation {
                    currentCoord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                } else {
                    currentCoord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
                }
                calculateDetailedRoutes(from: currentCoord)
                
            } catch {
                let message = error.localizedDescription.isEmpty ? "Unknown error" : error.localizedDescription
                print("❌ [StartTrip] Failed: \(message)")
                await MainActor.run {
                    startTripErrorMessage = "Couldn't start the trip. \(message)"
                    showStartTripError = true
                }
            }
        }
    }
    
    @State private var showTripSummary = false
    @State private var tripSummaryMessage = ""
    
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
     
     private func fetchVehicle() {
         Task {
             do {
                 let vehicles: [Vehicle] = try await supabase
                     .from("vehicles")
                     .select()
                     .eq("id", value: trip.vehicleId.uuidString)
                     .execute()
                     .value
                 
                 await MainActor.run {
                     assignedVehicle = vehicles.first
                 }
             } catch {
                 print("⚠️ Failed to fetch vehicle: \(error)")
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
            trip: .mockOngoingTrip,
            driverName: "John Doe",
            vehicleInfo: "Toyota Pris (XYZ 123)"
        )
    }
}

// MARK: - InAppVoiceReadable
extension TripMapView: InAppVoiceReadable {
    func voiceSummary() -> String {
        var summary = ""
        
        // Status
        if isCompleted {
            summary += "Trip Completed. "
            if let dist = trip.distance {
                 summary += "Total distance \(String(format: "%.1f", dist)) kilometers. "
            }
            return summary
        }
        
        // Current Phase
        if isPickupPhase {
            summary += "Navigating to Pickup. "
            summary += "Address: \(trip.startAddress ?? "Unknown address"). "
        } else {
            summary += "Navigating to Delivery. "
            summary += "Address: \(trip.endAddress ?? "Unknown address"). "
        }
        
        // Stats
        if let dist = routeDistance {
            summary += "Distance: \(String(format: "%.1f", dist)) kilometers. "
        }
        
        if let time = estimatedTime {
            summary += "Estimated time: \(time). "
        }
        
        // Alerts
        if routeMonitor.isOffRoute {
            summary += "Alert: You are off route. "
        }
        
        return summary
    }
}


