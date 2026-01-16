//
//  FleetManagerTripMapViewModel.swift
//  FleetTrack
//
//  Created for Fleet Manager Trip Map Integration
//

import Foundation
import Combine
import CoreLocation
import MapKit
import Supabase

@MainActor
class FleetManagerTripMapViewModel: ObservableObject {
    let tripId: UUID
    let vehicleId: UUID
    
    // Trip data
    @Published var trip: Trip?
    @Published var isLoading = false
    
    // Driver data
    @Published var driverName: String = "Loading..."
    @Published var driverPhone: String?
    
    // Providers
    @Published var locationProvider: RemoteLocationProvider
    
    // Route Data
    @Published var routePolyline: MKPolyline?
    @Published var totalDistance: Double = 0
    @Published var remainingDistance: Double = 0
    @Published var eta: Date?
    @Published var formattedEta: String?
    
    // State
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(tripId: UUID, vehicleId: UUID) {
        self.tripId = tripId
        self.vehicleId = vehicleId
        self.locationProvider = RemoteLocationProvider(vehicleId: vehicleId)
        
        setupSubscriptions()
    }
    
    func loadTripData() {
        isLoading = true
        Task {
            do {
                let response: Trip = try await supabase
                    .from("trips")
                    .select()
                    .eq("id", value: tripId.uuidString)
                    .limit(1)
                    .single()
                    .execute()
                    .value
                
                self.trip = response
                self.isLoading = false
                self.loadRoute()
                self.loadDriverData(driverId: response.driverId)
            } catch {
                self.errorMessage = "Failed to load trip: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func loadDriverData(driverId: UUID) {
        Task {
            do {
                // Fetch driver from the drivers table
                let driver: FMDriver = try await supabase
                    .from("drivers")
                    .select()
                    .eq("id", value: driverId.uuidString)
                    .limit(1)
                    .single()
                    .execute()
                    .value
                
                self.driverName = driver.fullName ?? "Unknown Driver"
                self.driverPhone = driver.phoneNumber
            } catch {
                print("Failed to load driver data: \(error)")
                self.driverName = "Unknown Driver"
            }
        }
    }
    
    func startTracking() {
        // Only track active trips
        if trip?.status == .ongoing {
            locationProvider.startTracking()
        }
    }
    
    func stopTracking() {
        locationProvider.stopTracking()
    }
    
    private func setupSubscriptions() {
        // Observe location updates to recalculate metrics
        locationProvider.$currentLocation
            .sink { [weak self] location in
                guard let self = self, let location = location else { return }
                self.recalculateMetrics(currentLocation: location)
            }
            .store(in: &cancellables)
    }
    
    private func loadRoute() {
        guard let trip = trip,
              let startLat = trip.startLat, let startLong = trip.startLong,
              let endLat = trip.endLat, let endLong = trip.endLong else {
            return
        }
        
        let start = CLLocationCoordinate2D(latitude: startLat, longitude: startLong)
        let end = CLLocationCoordinate2D(latitude: endLat, longitude: endLong)
        
        Task {
            do {
                let result = try await RouteCalculationService.shared.calculateRoute(from: start, to: end)
                self.routePolyline = result.polyline
                self.totalDistance = result.distance
                self.remainingDistance = result.distance // Initially full distance
            } catch {
                self.errorMessage = "Failed to load route: \(error.localizedDescription)"
            }
        }
    }
    
    private func recalculateMetrics(currentLocation: Location) {
        guard let trip = trip, let endLat = trip.endLat, let endLong = trip.endLong else { return }
        
        let currentLoc = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let endLoc = CLLocation(latitude: endLat, longitude: endLong)
        
        let directDistance = currentLoc.distance(from: endLoc)
        let estimatedRoadDistance = directDistance * 1.3
        
        self.remainingDistance = estimatedRoadDistance
        
        let speed = 11.1 // fallback m/s
        let secondsRemaining = estimatedRoadDistance / speed
        
        self.eta = Date().addingTimeInterval(secondsRemaining)
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        self.formattedEta = formatter.string(from: secondsRemaining)
    }
    
    var isLive: Bool {
        trip?.status == .ongoing
    }
    
    func callDriver() {
        guard let phone = driverPhone else { return }
        let cleanedPhone = phone.replacingOccurrences(of: " ", with: "")
        if let url = URL(string: "tel://\(cleanedPhone)") {
            UIApplication.shared.open(url)
        }
    }
}
