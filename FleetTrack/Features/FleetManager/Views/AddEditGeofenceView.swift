//
//  AddEditGeofenceView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI
import MapKit

struct AddEditGeofenceView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var manager = CircularGeofenceManager.shared
    
    // Optional geofence for edit mode
    let geofence: CircularGeofence?
    
    // Form State
    @State private var fenceName = ""
    @State private var radius: Double = 200 // meters
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var showResultsList = false
    @State private var isSaving = false
    
    // Map State
    @State private var centerCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    
    // Computed property to determine mode
    private var isEditMode: Bool {
        geofence != nil
    }
    
    var body: some View {
        ZStack {
            // Full Screen Map
            GeofenceSelectionMap(centerCoordinate: $centerCoordinate, radius: $radius)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header & Search
                VStack(spacing: 0) {
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        .accessibilityLabel("Cancel")
                        .accessibilityIdentifier("geofence_cancel_button")
                        Spacer()
                        Text(isEditMode ? "Edit Geofence" : "Add Geofence")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                        Spacer()
                        
                        if isSaving {
                             ProgressView()
                                .tint(.white)
                        } else {
                            Button(action: saveGeofence) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.appEmerald)
                                    .background(Color.white.clipShape(Circle())) // bg for checkmark visibility
                                    .shadow(radius: 4)
                            }
                            .disabled(fenceName.isEmpty)
                            .opacity(fenceName.isEmpty ? 0.6 : 1.0)
                            .accessibilityLabel("Save Geofence")
                            .accessibilityHint(fenceName.isEmpty ? "Required: Enter a zone name" : "Double tap to save this geofence")
                            .accessibilityIdentifier("geofence_save_button")
                        }
                    }
                    .padding()
                    
                    // Search Bar
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search Location...", text: $searchText, onCommit: performSearch)
                                .foregroundColor(.white)
                                .submitLabel(.search)
                                .accessibilityLabel("Search for a location")
                                .accessibilityIdentifier("geofence_search_field")
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                                .accessibilityLabel("Clear search")
                                .accessibilityIdentifier("geofence_search_clear_button")
                            }
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Search Results List
                        if showResultsList && !searchResults.isEmpty {
                            ScrollView {
                                VStack(alignment: .leading) {
                                    ForEach(searchResults, id: \.self) { item in
                                        Button(action: { selectLocation(item) }) {
                                            VStack(alignment: .leading) {
                                                Text(item.name ?? "Unknown")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 16, weight: .semibold))
                                                Text(item.addressRepresentations?.fullAddress(includingRegion: true, singleLine: true) ?? "")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .accessibilityLabel("Select \(item.name ?? "Unknown location")")
                                        .accessibilityIdentifier("geofence_search_result_\(item.name?.lowercased().replacingOccurrences(of: " ", with: "_") ?? "unknown")")
                                        Divider().background(Color.gray.opacity(0.3))
                                    }
                                }
                            }
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                            .frame(maxHeight: 200)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                }
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]), startPoint: .top, endPoint: .bottom)
                        .edgesIgnoringSafeArea(.top)
                )

                Spacer()
                
                // Bottom Controls Card
                VStack(spacing: 20) {
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Zone Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                        
                        TextField("e.g. Central Depot", text: $fenceName)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .accessibilityLabel("Zone Name")
                            .accessibilityIdentifier("geofence_name_field")
                    }
                    
                    // Radius Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Radius")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            Spacer()
                            Text("\(Int(radius)) m")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.appEmerald)
                        }
                        
                        Slider(value: $radius, in: 100...2000, step: 50)
                            .tint(.appEmerald)
                            .accessibilityLabel("Geofence Radius")
                            .accessibilityValue("\(Int(radius)) meters")
                            .accessibilityIdentifier("geofence_radius_slider")
                    }
                }
                .padding(24)
                .background(Color.appCardBackground) // Using app design token
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: -5)
                .padding()
            }
        }
        .onAppear {
            // Pre-populate fields if editing
            if let geofence = geofence {
                fenceName = geofence.name
                radius = geofence.radiusMeters
                centerCoordinate = CLLocationCoordinate2D(
                    latitude: geofence.latitude,
                    longitude: geofence.longitude
                )
            }
        }
    }
    
    // MARK: - Logic
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: 50000, longitudinalMeters: 50000) // Bias to current map center
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }
            self.searchResults = response.mapItems
            self.showResultsList = true
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        self.centerCoordinate = item.location.coordinate
        self.showResultsList = false
        self.searchText = "" // Clear search or keep it? Clearing to show map
        
        // Auto-fill name if empty
        if fenceName.isEmpty {
            fenceName = item.name ?? ""
        }
    }
    
    private func saveGeofence() {
        guard !fenceName.isEmpty else { return }
        isSaving = true
        
        let geofenceToSave = CircularGeofence(
            id: geofence?.id ?? UUID(),
            name: fenceName,
            latitude: centerCoordinate.latitude,
            longitude: centerCoordinate.longitude,
            radiusMeters: radius,
            notifyOnEntry: true,
            notifyOnExit: true,
            isActive: geofence?.isActive ?? true // Preserve status when editing, default to active when adding
        )
        
        Task {
            do {
                if isEditMode {
                    try await manager.updateGeofence(geofenceToSave)
                } else {
                    try await manager.saveGeofence(geofenceToSave)
                }
                await MainActor.run {
                    isSaving = false
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("Failed to \(isEditMode ? "update" : "save") geofence: \(error)")
                await MainActor.run {
                    isSaving = false
                    // Ideally show error alert
                }
            }
        }
    }
}

// MARK: - Map Component

struct GeofenceSelectionMap: UIViewRepresentable {
    @Binding var centerCoordinate: CLLocationCoordinate2D
    @Binding var radius: Double
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.isRotateEnabled = false
        
        // Add gesture recognizer for tap-to-place (if we want that later)
        // For now, dragging map sets center implicitly by map movement 
        // BUT standard MKMapView doesn't provide easy "centerDidChange" binding without delegate
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update Circle Overlay
        updateCircle(on: mapView)
        
        // If center coordinate changed externally (e.g. from search), move map
        // We compare with current center to avoid loop
        let mapCenter = mapView.centerCoordinate
        let threshold = 0.0001
        if abs(mapCenter.latitude - centerCoordinate.latitude) > threshold ||
            abs(mapCenter.longitude - centerCoordinate.longitude) > threshold {
            
            let region = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: radius * 4, longitudinalMeters: radius * 4)
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func updateCircle(on mapView: MKMapView) {
        // Remove old overlay
        mapView.removeOverlays(mapView.overlays)
        
        // Add new circle
        let circle = MKCircle(center: centerCoordinate, radius: radius)
        mapView.addOverlay(circle)
        
        // Optional: Add Pin
        mapView.removeAnnotations(mapView.annotations)
        let pin = MKPointAnnotation()
        pin.coordinate = centerCoordinate
        mapView.addAnnotation(pin)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: GeofenceSelectionMap
        
        init(_ parent: GeofenceSelectionMap) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circle)
                renderer.fillColor = UIColor.systemPurple.withAlphaComponent(0.2)
                renderer.strokeColor = UIColor.systemPurple
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        // Handle Map Movement to update Center Binding
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            // Note: This creates a 2-way binding loop if not careful.
            // But we actually WANT the user to drag the map to select the center.
            // So when map moves, we update parent.centerCoordinate.
            
            // To prevent jitter, we can check if it's user initiated or programmed.
            // For simplicity, we just update.
            DispatchQueue.main.async {
                self.parent.centerCoordinate = mapView.centerCoordinate
            }
        }
    }
}
