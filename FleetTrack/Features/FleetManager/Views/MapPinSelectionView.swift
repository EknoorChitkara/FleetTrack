//
//  MapPinSelectionView.swift
//  FleetTrack
//
//  Map pin selection for choosing locations by dragging map
//

import SwiftUI
import MapKit

struct MapPinSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var selectedAddress: String
    
    @State private var mapRegion: MKCoordinateRegion
    @State private var displayAddress: String = "Locating..."
    @State private var isGeocodingLocation = false
    @State private var dragTimer: Timer?
    
    let searchType: LocationSearchType
    let pinColor: Color
    
    init(selectedLocation: Binding<CLLocationCoordinate2D?>,
         selectedAddress: Binding<String>,
         searchType: LocationSearchType,
         initialRegion: MKCoordinateRegion) {
        self._selectedLocation = selectedLocation
        self._selectedAddress = selectedAddress
        self.searchType = searchType
        
        // Set pin color based on type
        self.pinColor = searchType == .pickup ? .green : Color(hex: "F9D854")
        
        // Initialize map region
        if let location = selectedLocation.wrappedValue {
            _mapRegion = State(initialValue: MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
            _displayAddress = State(initialValue: selectedAddress.wrappedValue)
        } else {
            _mapRegion = State(initialValue: initialRegion)
        }
    }
    
    var body: some View {
        ZStack {
            // Full-screen map
            MapView(region: $mapRegion, onRegionChange: handleRegionChange)
                .edgesIgnoringSafeArea(.all)
            
            // Center pin (stays fixed while map moves)
            VStack {
                Spacer()
                
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(pinColor)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                    .offset(y: -25) // Offset to point at actual location
                
                Spacer()
            }
            
            // Close button
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
            }
            
            // Bottom sheet with address and confirm button
            VStack {
                Spacer()
                bottomSheet
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationBarHidden(true)
        .onAppear {
            // Geocode initial location
            reverseGeocodeCenter()
        }
    }
    
    // MARK: - Bottom Sheet
    
    private var bottomSheet: some View {
        VStack(spacing: 16) {
            // Drag handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Selected location info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(pinColor)
                    
                    Text("Selected Location")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appSecondaryText)
                        .textCase(.uppercase)
                }
                
                if isGeocodingLocation {
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(.appEmerald)
                        
                        Text("Getting address...")
                            .font(.system(size: 16))
                            .foregroundColor(.appSecondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                } else {
                    Text(displayAddress)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Confirm button
            Button(action: {
                confirmLocation()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("Confirm Location")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(Color.appBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isGeocodingLocation ? Color.gray.opacity(0.3) : Color(hex: "F9D854"))
                )
            }
            .disabled(isGeocodingLocation)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.appCardBackground.opacity(0.98))
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: -5)
        )
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }
    
    // MARK: - Helpers
    
    private func handleRegionChange() {
        // Cancel previous timer
        dragTimer?.invalidate()
        
        // Set new timer to geocode after user stops dragging
        dragTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            reverseGeocodeCenter()
        }
    }
    
    private func reverseGeocodeCenter() {
        let center = mapRegion.center
        isGeocodingLocation = true
        
        Task {
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: center.latitude, longitude: center.longitude)
            
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                
                if let placemark = placemarks.first {
                    let address = formatAddress(from: placemark)
                    await MainActor.run {
                        displayAddress = address
                        isGeocodingLocation = false
                    }
                }
            } catch {
                await MainActor.run {
                    displayAddress = "Unable to get address"
                    isGeocodingLocation = false
                }
            }
        }
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let name = placemark.name {
            components.append(name)
        }
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        return components.isEmpty ? "Unknown location" : components.joined(separator: ", ")
    }
    
    private func confirmLocation() {
        selectedLocation = mapRegion.center
        selectedAddress = displayAddress
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Map View

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var onRegionChange: () -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .mutedStandard
        mapView.showsUserLocation = false
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        if !context.coordinator.isUpdating {
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(region: $region, onRegionChange: onRegionChange)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        @Binding var region: MKCoordinateRegion
        var onRegionChange: () -> Void
        var isUpdating = false
        
        init(region: Binding<MKCoordinateRegion>, onRegionChange: @escaping () -> Void) {
            self._region = region
            self.onRegionChange = onRegionChange
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            isUpdating = true
            region = mapView.region
            isUpdating = false
            onRegionChange()
        }
    }
}
