//
//  PlanTripView.swift
//  FleetTrack
//
//  Redesigned with full-screen MapKit integration and floating overlays
//

import SwiftUI
import MapKit

struct PlanTripView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fleetVM: FleetViewModel
    @StateObject private var viewModel = PlanTripViewModel()
    
    @State private var bottomSheetHeight: CGFloat = 180
    @State private var dragOffset: CGFloat = 0
    
    // Location input method states
    @State private var showingStartSearch = false
    @State private var showingEndSearch = false
    @State private var showingStartPinSelection = false
    @State private var showingEndPinSelection = false
    
    private let minBottomSheetHeight: CGFloat = 180
    private let maxBottomSheetHeight: CGFloat = 500
    
    var body: some View {
        ZStack(alignment: .top) {
            // Full-screen map background
            PlanTripMapView(
                startCoordinate: viewModel.startCoordinate,
                endCoordinate: viewModel.endCoordinate,
                routePolyline: viewModel.routePolyline,
                region: $viewModel.mapRegion
            )
            .edgesIgnoringSafeArea(.all)
            .overlay(
                Group {
                    if viewModel.isCalculatingRoute {
                        VStack {
                            ProgressView()
                                .tint(.white)
                            Text("Calculating route...")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.top, 4)
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                    }
                }
            )
            
            VStack(spacing: 0) {
                // Floating header
                floatingHeader
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Floating address input card
                addressCard
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                Spacer()
            }
            
            // Draggable bottom sheet
            VStack {
                Spacer()
                bottomSheet
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingStartSearch) {
            LocationSearchView(
                selectedLocation: $viewModel.startCoordinate,
                selectedAddress: $viewModel.startAddress,
                searchType: .pickup,
                currentRegion: viewModel.mapRegion
            )
        }
        .sheet(isPresented: $showingEndSearch) {
            LocationSearchView(
                selectedLocation: $viewModel.endCoordinate,
                selectedAddress: $viewModel.endAddress,
                searchType: .dropoff,
                currentRegion: viewModel.mapRegion
            )
        }
        .sheet(isPresented: $showingStartPinSelection) {
            MapPinSelectionView(
                selectedLocation: $viewModel.startCoordinate,
                selectedAddress: $viewModel.startAddress,
                searchType: .pickup,
                initialRegion: viewModel.mapRegion
            )
        }
        .sheet(isPresented: $showingEndPinSelection) {
            MapPinSelectionView(
                selectedLocation: $viewModel.endCoordinate,
                selectedAddress: $viewModel.endAddress,
                searchType: .dropoff,
                initialRegion: viewModel.mapRegion
            )
        }
        .alert("Invalid Location", isPresented: $viewModel.showingSameLocationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Pickup and drop-off locations cannot be the same.")
        }
    }
    
    // MARK: - Floating Header
    
    private var floatingHeader: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }
            
            Spacer()
            
            Text("Good Afternoon!")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
    
    // MARK: - Address Card
    
    private var addressCard: some View {
        VStack(spacing: 12) {
            // Title
            Text("Plan Trip")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            
            // Pickup Address
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                
                TextField("Pickup Location", text: $viewModel.startAddress)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                
                Spacer()
                
                if viewModel.isGeocodingStart {
                    ProgressView()
                        .tint(.appEmerald)
                } else {
                    // Search button
                    Button(action: { showingStartSearch = true }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.appEmerald)
                    }
                    
                    // Pin button
                    Button(action: { showingStartPinSelection = true }) {
                        Image(systemName: "mappin")
                            .font(.system(size: 16))
                            .foregroundColor(.appEmerald)
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(Color.black.opacity(0.3))
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            
            // Dropoff Address
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: "F9D854"))
                    .frame(width: 12, height: 12)
                
                TextField("Dropoff Location", text: $viewModel.endAddress)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                
                Spacer()
                
                if viewModel.isGeocodingEnd {
                    ProgressView()
                        .tint(.appEmerald)
                } else {
                    // Search button
                    Button(action: { showingEndSearch = true }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.appEmerald)
                    }
                    
                    // Pin button
                    Button(action: { showingEndPinSelection = true }) {
                        Image(systemName: "mappin")
                            .font(.system(size: 16))
                            .foregroundColor(.appEmerald)
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(Color.black.opacity(0.3))
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color.appCardBackground.opacity(0.95))
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Bottom Sheet
    
    private var bottomSheet: some View {
        VStack(spacing: 0) {
            // Drag Handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    // Date and Status
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundColor(.appSecondaryText)
                            
                            DatePicker("", selection: $viewModel.startTime, in: viewModel.tripDateRange, displayedComponents: [.date])
                                .labelsHidden()
                                .colorScheme(.dark)
                                .accentColor(.appEmerald)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 12))
                            Text("Available")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    
                    // Vehicle Selector
                    vehicleSelector
                    
                    // Plan Trip Button
                    planTripButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .frame(height: bottomSheetHeight + dragOffset)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.appCardBackground.opacity(0.98))
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: -5)
        )
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = -value.translation.height
                }
                .onEnded { value in
                    let newHeight = bottomSheetHeight + dragOffset
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if newHeight < (minBottomSheetHeight + maxBottomSheetHeight) / 2 {
                            bottomSheetHeight = minBottomSheetHeight
                        } else {
                            bottomSheetHeight = maxBottomSheetHeight
                        }
                        dragOffset = 0
                    }
                }
        )
    }
    
    // MARK: - Driver Selector
    
    private var driverSelector: some View {
        Menu {
            Button("Select Driver") {
                viewModel.driverId = nil
            }
            ForEach(fleetVM.drivers.filter { $0.isActive == true }) { driver in
                Button(driver.displayName) {
                    viewModel.driverId = driver.id
                    // Auto-assign vehicle if driver has one
                    if let vehicle = fleetVM.vehicles.first(where: { $0.assignedDriverId == driver.id }) {
                        viewModel.vehicleId = vehicle.id
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(viewModel.driverId != nil ? .appEmerald : .appSecondaryText)
                
                if let driverId = viewModel.driverId,
                   let driver = fleetVM.drivers.first(where: { $0.id == driverId }) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(driver.displayName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        if let phone = driver.phoneNumber {
                            Text(phone)
                                .font(.system(size: 12))
                                .foregroundColor(.appSecondaryText)
                        }
                    }
                } else {
                    Text("Select Driver")
                        .foregroundColor(.appSecondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.appSecondaryText)
            }
            .padding()
            .background(Color.black.opacity(0.2))
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Vehicle Selector
    
    private var vehicleSelector: some View {
        Menu {
            Button("Select Vehicle") {
                viewModel.vehicleId = nil
                viewModel.driverId = nil
            }
            ForEach(availableVehicles) { vehicle in
                Button(action: {
                    viewModel.vehicleId = vehicle.id
                    // Enforce driver assignment from vehicle
                    if let driverId = vehicle.assignedDriverId {
                        viewModel.driverId = driverId
                    } else {
                        viewModel.driverId = nil // Should not happen if filtered correctly
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(vehicle.manufacturer) \(vehicle.model)")
                                .font(.system(size: 15, weight: .medium))
                            Text(vehicle.registrationNumber)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Show assigned driver name
                        if let driverId = vehicle.assignedDriverId,
                           let driver = fleetVM.drivers.first(where: { $0.id == driverId }) {
                            Text("Driver: \(driver.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No Driver")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundColor(viewModel.vehicleId != nil ? .appEmerald : .appSecondaryText)
                
                if let vehicleId = viewModel.vehicleId,
                   let vehicle = fleetVM.vehicles.first(where: { $0.id == vehicleId }) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(vehicle.manufacturer) \(vehicle.model) (\(vehicle.registrationNumber))")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        
                        // Show assigned driver below vehicle
                        if let driverId = viewModel.driverId,
                           let driver = fleetVM.drivers.first(where: { $0.id == driverId }) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 10))
                                Text("Driver: \(driver.displayName)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.appEmerald)
                            }
                        } else {
                            Text("No Driver Assigned")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    Text("Select Vehicle")
                        .foregroundColor(.appSecondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.appSecondaryText)
            }
            .padding()
            .background(Color.black.opacity(0.2))
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
    
    // Filter vehicles based on availability and proximity to pickup
    private var availableVehicles: [FMVehicle] {
        let busyVehicleIds = Set(fleetVM.trips
            .filter { $0.status == "In Progress" || $0.status == "Scheduled" }
            .map { $0.vehicleId })
        
        return fleetVM.vehicles.filter { vehicle in
            // Only show active vehicles that have an assigned driver AND are not currently busy
            vehicle.status == .active && vehicle.assignedDriverId != nil && !busyVehicleIds.contains(vehicle.id)
        }
    }
    
    // MARK: - Plan Trip Button
    
    private var planTripButton: some View {
        Button(action: {
            viewModel.createTrip(fleetVM: fleetVM) { success in
                if success {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }) {
            HStack {
                Image(systemName: "map.fill")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Plan Trip")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(Color.appBackground)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(viewModel.isFormValid ? Color(hex: "F9D854") : Color.gray.opacity(0.3))
            )
        }
        .disabled(!viewModel.isFormValid)
        .padding(.top, 8)
    }
}

// MARK: - Plan Trip Map View

struct PlanTripMapView: UIViewRepresentable {
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?
    let routePolyline: MKPolyline?
    @Binding var region: MKCoordinateRegion
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .mutedStandard
        mapView.showsUserLocation = false
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region
        mapView.setRegion(region, animated: true)
        
        // Remove old annotations and overlays
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        // Add start annotation
        if let start = startCoordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = start
            annotation.title = "Pickup"
            mapView.addAnnotation(annotation)
        }
        
        // Add end annotation
        if let end = endCoordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = end
            annotation.title = "Dropoff"
            mapView.addAnnotation(annotation)
        }
        
        // Add route polyline
        if let polyline = routePolyline {
            mapView.addOverlay(polyline)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(red: 0.98, green: 0.85, blue: 0.33, alpha: 1.0) // Yellow
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "pin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                view?.annotation = annotation
            }
            
            if annotation.title == "Pickup" {
                view?.markerTintColor = .green
                view?.glyphImage = UIImage(systemName: "figure.walk")
            } else {
                view?.markerTintColor = UIColor(red: 0.98, green: 0.85, blue: 0.33, alpha: 1.0)
                view?.glyphImage = UIImage(systemName: "flag.checkered")
            }
            
            return view
        }
    }
}
