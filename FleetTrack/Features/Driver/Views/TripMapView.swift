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
    @StateObject private var locationManager = DriverLocationManager()
    
    @State private var showArriveAlert = false
    @State private var showCompleteAlert = false
    @State private var estimatedTime: String?
    @State private var routeDistance: Double?
    @State private var isNavigating = false
    
    // Trip phases
    var isCompleted: Bool { trip.status == .completed }
    var isPickupPhase: Bool { trip.status == .scheduled }
    var isDeliveryPhase: Bool { trip.status == .ongoing }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map view based on status
            if isCompleted {
                // Completed trip: Show static route summary
                CompletedTripMap(trip: trip)
                    .ignoresSafeArea(edges: .bottom)
            } else {
                // Active trip: Show live tracking
                LiveTripMap(
                    trip: trip,
                    locationManager: locationManager,
                    showPickupRoute: isPickupPhase,
                    isNavigating: isNavigating,
                    estimatedTime: $estimatedTime,
                    routeDistance: $routeDistance
                )
                .ignoresSafeArea(edges: .bottom)
            }
            
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
        }
        .alert("Arrived at Pickup?", isPresented: $showArriveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Start Delivery") { startDelivery() }
        } message: {
            Text("Confirm you've picked up the package and ready to deliver?")
        }
        .alert("Complete Delivery?", isPresented: $showCompleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Complete") { completeTrip() }
        } message: {
            Text("Confirm delivery to \(trip.endAddress ?? "destination")?")
        }
        .onAppear {
            if !isCompleted {
                locationManager.startTracking()
            }
        }
        .onDisappear {
            locationManager.stopTracking()
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
                    Label("Arrived at Pickup", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            } else if isDeliveryPhase {
                Button { showCompleteAlert = true } label: {
                    Label("Mark as Delivered", systemImage: "flag.checkered")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
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
            try? await supabase.from("trips")
                .update(["status": "In Progress", "start_time": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: trip.id).execute()
            await MainActor.run { dismiss() }
        }
    }
    
    private func completeTrip() {
        Task {
            try? await supabase.from("trips")
                .update(["status": "Completed", "end_time": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: trip.id).execute()
            await MainActor.run { dismiss() }
        }
    }
}

// MARK: - Completed Trip Map (Static)

struct CompletedTripMap: UIViewRepresentable {
    let trip: Trip
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.isUserInteractionEnabled = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        guard !context.coordinator.isConfigured else { return }
        context.coordinator.isConfigured = true
        
        guard let startLat = trip.startLat, let startLong = trip.startLong,
              let endLat = trip.endLat, let endLong = trip.endLong else { return }
        
        let startCoord = CLLocationCoordinate2D(latitude: startLat, longitude: startLong)
        let endCoord = CLLocationCoordinate2D(latitude: endLat, longitude: endLong)
        
        // Add annotations
        let pickupAnnotation = MKPointAnnotation()
        pickupAnnotation.coordinate = startCoord
        pickupAnnotation.title = "Pickup"
        pickupAnnotation.subtitle = trip.startAddress
        
        let dropoffAnnotation = MKPointAnnotation()
        dropoffAnnotation.coordinate = endCoord
        dropoffAnnotation.title = "Dropoff"
        dropoffAnnotation.subtitle = trip.endAddress
        
        mapView.addAnnotations([pickupAnnotation, dropoffAnnotation])
        
        // Calculate route
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoord))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endCoord))
        request.transportType = .automobile
        
        MKDirections(request: request).calculate { response, _ in
            guard let route = response?.routes.first else {
                mapView.showAnnotations(mapView.annotations, animated: true)
                return
            }
            mapView.addOverlay(route.polyline, level: .aboveRoads)
            let padding = UIEdgeInsets(top: 80, left: 40, bottom: 280, right: 40)
            mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: padding, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var isConfigured = false
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemGreen // Green for completed
                renderer.lineWidth = 5
                renderer.lineCap = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            view.canShowCallout = true
            if annotation.title == "Pickup" {
                view.markerTintColor = .systemGreen
                view.glyphImage = UIImage(systemName: "shippingbox.fill")
            } else {
                view.markerTintColor = .systemRed
                view.glyphImage = UIImage(systemName: "flag.fill")
            }
            return view
        }
    }
}

// MARK: - Driver Location Manager

class DriverLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
    }
    
    func startTracking() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func stopTracking() {
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last?.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error)")
    }
}

// MARK: - Live Trip Map

struct LiveTripMap: UIViewRepresentable {
    let trip: Trip
    @ObservedObject var locationManager: DriverLocationManager
    let showPickupRoute: Bool
    let isNavigating: Bool
    @Binding var estimatedTime: String?
    @Binding var routeDistance: Double?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        if isNavigating {
            mapView.userTrackingMode = .followWithHeading
        }
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        if !context.coordinator.isConfigured {
            setupMap(mapView: mapView, context: context)
            context.coordinator.isConfigured = true
        }
        
        // Recalculate route when location updates significantly
        if let loc = locationManager.location, context.coordinator.shouldRecalculate(from: loc) {
            calculateRoute(mapView: mapView, from: loc, context: context)
        }
    }
    
    private func setupMap(mapView: MKMapView, context: Context) {
        guard let startLat = trip.startLat, let startLong = trip.startLong,
              let endLat = trip.endLat, let endLong = trip.endLong else { return }
        
        let pickupAnnotation = MKPointAnnotation()
        pickupAnnotation.coordinate = CLLocationCoordinate2D(latitude: startLat, longitude: startLong)
        pickupAnnotation.title = "Pickup"
        
        let dropoffAnnotation = MKPointAnnotation()
        dropoffAnnotation.coordinate = CLLocationCoordinate2D(latitude: endLat, longitude: endLong)
        dropoffAnnotation.title = "Dropoff"
        
        mapView.addAnnotations([pickupAnnotation, dropoffAnnotation])
    }
    
    private func calculateRoute(mapView: MKMapView, from userLoc: CLLocationCoordinate2D, context: Context) {
        context.coordinator.lastLocation = userLoc
        mapView.removeOverlays(mapView.overlays)
        
        let destCoord: CLLocationCoordinate2D
        if showPickupRoute {
            guard let lat = trip.startLat, let lon = trip.startLong else { return }
            destCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            guard let lat = trip.endLat, let lon = trip.endLong else { return }
            destCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLoc))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destCoord))
        request.transportType = .automobile
        
        MKDirections(request: request).calculate { response, _ in
            guard let route = response?.routes.first else { return }
            mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            DispatchQueue.main.async {
                let formatter = DateComponentsFormatter()
                formatter.allowedUnits = [.hour, .minute]
                formatter.unitsStyle = .abbreviated
                self.estimatedTime = formatter.string(from: route.expectedTravelTime)
                self.routeDistance = route.distance / 1000
            }
            
            if !self.isNavigating {
                let padding = UIEdgeInsets(top: 80, left: 40, bottom: 280, right: 40)
                mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: padding, animated: true)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var isConfigured = false
        var lastLocation: CLLocationCoordinate2D?
        
        func shouldRecalculate(from newLoc: CLLocationCoordinate2D) -> Bool {
            guard let last = lastLocation else { return true }
            let dist = CLLocation(latitude: last.latitude, longitude: last.longitude)
                .distance(from: CLLocation(latitude: newLoc.latitude, longitude: newLoc.longitude))
            return dist > 200
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            view.canShowCallout = true
            view.markerTintColor = annotation.title == "Pickup" ? .systemGreen : .systemRed
            view.glyphImage = UIImage(systemName: annotation.title == "Pickup" ? "shippingbox.fill" : "flag.fill")
            return view
        }
    }
}

#Preview {
    NavigationStack {
        TripMapView(trip: Trip.mockCompletedTrip)
    }
}
