//
//  RouteCalculationService.swift
//  FleetTrack
//
//  Calculates routes and provides navigation details
//  Phase 3: Route Calculation
//

import MapKit

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
    
    /// Get alternative routes
    func getAlternativeRoutes(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType = .automobile
    ) async throws -> [RouteResult] {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = transportType
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        return response.routes.map { route in
            RouteResult(
                route: route,
                distance: route.distance,
                expectedTravelTime: route.expectedTravelTime,
                polyline: route.polyline,
                steps: route.steps
            )
        }
    }
    
    /// Calculate ETA (Estimated Time of Arrival)
    func calculateETA(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) async throws -> Date {
        let result = try await calculateRoute(from: from, to: to)
        return Date().addingTimeInterval(result.expectedTravelTime)
    }
}
