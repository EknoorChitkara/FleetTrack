//
//  RouteCalculationService.swift
//  FleetTrack
//
//  Calculates routes and provides navigation details
//  Phase 3: Route Calculation
//

import MapKit
import SwiftData

struct RouteResult {
    let route: MKRoute
    let distance: Double // meters
    let expectedTravelTime: TimeInterval // seconds
    let polyline: MKPolyline
    let steps: [MKRoute.Step]
    
    var distanceInKilometers: Double {
        distance / 1000.0
    }
    
    var formattedDistance: String {
        String(format: "%.1f km", distanceInKilometers)
    }
    
    var formattedDuration: String {
        let hours = Int(expectedTravelTime) / 3600
        let minutes = Int(expectedTravelTime) / 60 % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
}

class RouteCalculationService {
    static let shared = RouteCalculationService()
    
    private init() {}
    
    // MARK: - Route Calculation
    
    /// Calculate route between two coordinates
    func calculateRoute(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType = .automobile
    ) async throws -> RouteResult {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = transportType
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        guard let route = response.routes.first else {
            throw LocationError.geocodingFailed("No route found")
        }
        
        return RouteResult(
            route: route,
            distance: route.distance,
            expectedTravelTime: route.expectedTravelTime,
            polyline: route.polyline,
            steps: route.steps
        )
    }
    
    /// Get alternative routes (Returning RouteResult wrapper)
    func getAlternativeRoutes(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType = .automobile
    ) async throws -> [RouteResult] {
        let routes = try await fetchRawRoutes(from: from, to: to, transportType: transportType)
        
        return routes.map { route in
            RouteResult(
                route: route,
                distance: route.distance,
                expectedTravelTime: route.expectedTravelTime,
                polyline: route.polyline,
                steps: route.steps
            )
        }
    }
    
    /// Fetch raw MKRoutes (Internal/Shared use)
    func fetchRawRoutes(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType = .automobile
    ) async throws -> [MKRoute] {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = transportType
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        return response.routes
    }
    
    /// Calculate ETA (Estimated Time of Arrival)
    func calculateETA(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) async throws -> Date {
        let result = try await calculateRoute(from: from, to: to)
        return Date().addingTimeInterval(result.expectedTravelTime)
    }
    
    // MARK: - Offline Route Caching
    
    /// Cache a route for offline use
    @MainActor
    func cacheRoute(tripId: UUID, route: RouteResult, modelContext: ModelContext) {
        // Extract coordinates from polyline
        let polyline = route.polyline
        var coordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: polyline.pointCount)
        polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: polyline.pointCount))
        
        // Encode coordinates
        let encodedData = CachedRoute.encodeCoordinates(coordinates)
        
        // Extract step instructions
        let steps = route.steps.compactMap { $0.instructions }.filter { !$0.isEmpty }
        
        // Create and save cached route
        let cachedRoute = CachedRoute(
            tripId: tripId,
            polylineData: encodedData,
            steps: steps,
            totalDistance: route.distance,
            estimatedTime: route.expectedTravelTime
        )
        
        modelContext.insert(cachedRoute)
        try? modelContext.save()
        
        print("✅ Route cached for trip \(tripId)")
    }
    
    /// Load a cached route for offline display
    @MainActor
    func loadCachedRoute(tripId: UUID, modelContext: ModelContext) -> CachedRoute? {
        let descriptor = FetchDescriptor<CachedRoute>(
            predicate: #Predicate { $0.tripId == tripId }
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            if let cached = results.first {
                print("📦 Loaded cached route for trip \(tripId)")
                return cached
            }
        } catch {
            print("❌ Failed to load cached route: \(error)")
        }
        
        return nil
    }
    
    /// Delete cached route after trip completion
    @MainActor
    func deleteCachedRoute(tripId: UUID, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<CachedRoute>(
            predicate: #Predicate { $0.tripId == tripId }
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            for route in results {
                modelContext.delete(route)
            }
            try modelContext.save()
            print("🗑️ Deleted cached route for trip \(tripId)")
        } catch {
            print("❌ Failed to delete cached route: \(error)")
        }
    }
}
