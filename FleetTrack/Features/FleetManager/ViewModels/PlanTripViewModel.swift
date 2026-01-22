//
//  PlanTripViewModel.swift
//  FleetTrack
//
//  ViewModel for Plan Trip with MapKit integration
//

import Foundation
import SwiftUI
import MapKit
import Combine

@MainActor
class PlanTripViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    // Form Data
    @Published var vehicleId: UUID?
    @Published var driverId: UUID?
    @Published var startAddress: String = ""
    @Published var endAddress: String = ""
    @Published var purpose: String = ""
    @Published var startTime: Date = Date()
    
    // Map State
    @Published var startCoordinate: CLLocationCoordinate2D?
    @Published var endCoordinate: CLLocationCoordinate2D?
    @Published var routePolyline: MKPolyline?
    @Published var distance: Double = 0
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 30.7333, longitude: 76.7794), // Chandigarh default
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    // Suggestions
    @Published var pickupSuggestions: [MKLocalSearchCompletion] = []
    @Published var dropoffSuggestions: [MKLocalSearchCompletion] = []
    @Published var showPickupSuggestions = false
    @Published var showDropoffSuggestions = false
    
    private let completer = MKLocalSearchCompleter()
    private var currentSearchType: SearchType?
    
    enum SearchType {
        case pickup, dropoff
    }
    
    // UI State
    @Published var isGeocodingStart = false
    @Published var isGeocodingEnd = false
    @Published var isCalculatingRoute = false
    @Published var errorMessage: String?
    @Published var showingSameLocationAlert = false
    
    private var geocodingTask: Task<Void, Never>?
    
    // Debounce addresses
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.region = mapRegion
        setupAddressObservers()
    }
    
    private func setupAddressObservers() {
        // Observers for live search suggestions
        $startAddress
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] address in
                guard let self = self else { return }
                if !address.isEmpty && self.currentSearchType != .pickup {
                    self.currentSearchType = .pickup
                    self.completer.queryFragment = address
                } else if address.isEmpty {
                    self.pickupSuggestions = []
                    self.showPickupSuggestions = false
                }
            }
            .store(in: &cancellables)
            
        $endAddress
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] address in
                guard let self = self else { return }
                if !address.isEmpty && self.currentSearchType != .dropoff {
                    self.currentSearchType = .dropoff
                    self.completer.queryFragment = address
                } else if address.isEmpty {
                    self.dropoffSuggestions = []
                    self.showDropoffSuggestions = false
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - MKLocalSearchCompleterDelegate
    
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            if self.currentSearchType == .pickup {
                self.pickupSuggestions = completer.results
                self.showPickupSuggestions = !completer.results.isEmpty
            } else if self.currentSearchType == .dropoff {
                self.dropoffSuggestions = completer.results
                self.showDropoffSuggestions = !completer.results.isEmpty
            }
        }
    }
    
    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Completer error: \(error.localizedDescription)")
    }
    
    // Selecting a suggestion
    func selectPickupSuggestion(_ suggestion: MKLocalSearchCompletion) {
        startAddress = suggestion.title
        showPickupSuggestions = false
        currentSearchType = nil // Reset so further typing triggers completer
        Task { await geocodeStartAddress(suggestion.title) }
    }
    
    func selectDropoffSuggestion(_ suggestion: MKLocalSearchCompletion) {
        endAddress = suggestion.title
        showDropoffSuggestions = false
        currentSearchType = nil
        Task { await geocodeEndAddress(suggestion.title) }
    }
    
    private func geocodeStartAddress(_ address: String) async {
        isGeocodingStart = true
        
        do {
            let coordinate = try await GeocodingService.shared.geocode(address: address)
            self.startCoordinate = coordinate
            updateMapRegion()
            
            // If both coordinates available, calculate route
            if endCoordinate != nil {
                await calculateRoute()
            }
        } catch {
            print("Geocoding start address failed: \(error)")
        }
        
        if let start = startCoordinate, let end = endCoordinate,
           start.latitude == end.latitude, start.longitude == end.longitude {
            showingSameLocationAlert = true
        }
        
        isGeocodingStart = false
    }
    
    private func geocodeEndAddress(_ address: String) async {
        isGeocodingEnd = true
        
        do {
            let coordinate = try await GeocodingService.shared.geocode(address: address)
            self.endCoordinate = coordinate
            updateMapRegion()
            
            // If both coordinates available, calculate route
            if startCoordinate != nil {
                await calculateRoute()
            }
        } catch {
            print("Geocoding end address failed: \(error)")
        }
        
        if let start = startCoordinate, let end = endCoordinate,
           start.latitude == end.latitude, start.longitude == end.longitude {
            showingSameLocationAlert = true
        }
        
        isGeocodingEnd = false
    }
    
    private func calculateRoute() async {
        guard let start = startCoordinate, let end = endCoordinate else { return }
        
        isCalculatingRoute = true
        
        do {
            let result = try await RouteCalculationService.shared.calculateRoute(from: start, to: end)
            self.routePolyline = result.polyline
            self.distance = result.distance / 1000 // Convert to km
            
            // Update region to show entire route
            let polyline = result.polyline
            if true {
                let rect = polyline.boundingMapRect
                let region = MKCoordinateRegion(rect)
                let padding: Double = 1.3
                self.mapRegion = MKCoordinateRegion(
                    center: region.center,
                    span: MKCoordinateSpan(
                        latitudeDelta: region.span.latitudeDelta * padding,
                        longitudeDelta: region.span.longitudeDelta * padding
                    )
                )
            }
        } catch {
            print("Route calculation failed: \(error)")
            errorMessage = "Could not calculate route"
        }
        
        isCalculatingRoute = false
    }
    
    private func updateMapRegion() {
        if let start = startCoordinate, let end = endCoordinate {
            // Center map between both points
            let centerLat = (start.latitude + end.latitude) / 2
            let centerLon = (start.longitude + end.longitude) / 2
            let latDelta = abs(start.latitude - end.latitude) * 1.5
            let lonDelta = abs(start.longitude - end.longitude) * 1.5
            
            mapRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(latitudeDelta: max(latDelta, 0.05), longitudeDelta: max(lonDelta, 0.05))
            )
        } else if let start = startCoordinate {
            mapRegion.center = start
        } else if let end = endCoordinate {
            mapRegion.center = end
        }
    }
    
    func createTrip(fleetVM: FleetViewModel, completion: @escaping (Bool) -> Void) {
        guard isFormValid else {
            errorMessage = "Please fill all required fields"
            completion(false)
            return
        }
        
        let tripData = TripCreationData(
            vehicleId: vehicleId,
            driverId: driverId,
            startAddress: startAddress,
            endAddress: endAddress,
            startLatitude: startCoordinate?.latitude,
            startLongitude: startCoordinate?.longitude,
            endLatitude: endCoordinate?.latitude,
            endLongitude: endCoordinate?.longitude,
            distance: distance,
            startTime: startTime,
            purpose: purpose
        )
        
        if let assignedDriverId = driverId,
           let driver = fleetVM.drivers.first(where: { $0.id == assignedDriverId }) {
            print("Assigning trip to driver: \(driver.fullName)")
            print("Driver Email: \(driver.email)")
        }
        
        fleetVM.addTrip(tripData)
        completion(true)
    }
    
    var isFormValid: Bool {
        vehicleId != nil &&
        driverId != nil &&
        !startAddress.isEmpty &&
        !endAddress.isEmpty &&
        startCoordinate != nil &&
        endCoordinate != nil &&
        !isLocationSame
    }
    
    var isLocationSame: Bool {
        guard let start = startCoordinate, let end = endCoordinate else {
            return false
        }
        return start.latitude == end.latitude && start.longitude == end.longitude
    }
    
    var tripDateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let components = calendar.dateComponents([.year], from: today)
        guard let year = components.year,
              let lastDayOfYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31, hour: 23, minute: 59, second: 59)) else {
            return today...today
        }
        
        return today...lastDayOfYear
    }
}
