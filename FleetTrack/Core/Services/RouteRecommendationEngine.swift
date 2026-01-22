//
//  RouteRecommendationEngine.swift
//  FleetTrack
//
//  Facade for fetching and ranking routes.
//

import Foundation
import CoreLocation
import MapKit

class RouteRecommendationEngine {
    static let shared = RouteRecommendationEngine()
    
    private init() {}
    
    /// Calculate best routes
    /// - Parameters:
    ///   - start: Start Coordinate
    ///   - end: End Coordinate
    /// - Returns: List of Scored Routes, sorted by score.
    func findBestRoutes(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async throws -> [ScoredRoute] {
        
        // 1. Fetch raw routes from MapKit (request alternates)
        let rawRoutes = try await RouteCalculationService.shared.fetchRawRoutes(from: start, to: end)
        
        // 2. Score routes
        let scoredRoutes = RouteScoringService.shared.scoreRoutes(rawRoutes)
        
        return scoredRoutes
    }
}
