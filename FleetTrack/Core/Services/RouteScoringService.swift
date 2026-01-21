//
//  RouteScoringService.swift
//  FleetTrack
//
//  Scores routes to find the best balance between time, fuel, and traffic.
//

import Foundation
import MapKit

enum RouteType: String, CaseIterable {
    case fastest = "Fastest"
    case fuelEfficient = "Fuel Saver"
    case balanced = "Balanced"
}

struct ScoredRoute: Identifiable {
    let id = UUID()
    let route: MKRoute
    let routeType: RouteType
    let score: Double
    let fuelEstimate: FuelEstimate
    let isRecommended: Bool
    
    // Pass-through properties
    var distance: Double { route.distance }
    var expectedTravelTime: TimeInterval { route.expectedTravelTime }
    var polyline: MKPolyline { route.polyline }
}

class RouteScoringService {
    static let shared = RouteScoringService()
    
    private init() {}
    
    // Weights for scoring (Lower score is better)
    private let speedWeight: Double = 0.5   // Priority on time
    private let fuelWeight: Double = 0.3    // Priority on efficiency
    private let trafficWeight: Double = 0.2 // Priority on avoiding traffic
    
    func scoreRoutes(_ routes: [MKRoute]) -> [ScoredRoute] {
        guard !routes.isEmpty else { return [] }
        
        // 1. Analyze each route
        var analyzedRoutes: [(route: MKRoute, score: Double, fuel: FuelEstimate)] = []
        
        for route in routes {
            let fuel = FuelEstimationService.shared.estimateFuel(
                distanceMeters: route.distance,
                expectedTravelTime: route.expectedTravelTime
            )
            
            // Normalize values for scoring
            // We use raw values for now, but in a robust system we'd normalize across the set
            let timeScore = route.expectedTravelTime * speedWeight
            // Fuel score: Convert liters to a comparable "cost" unit (arbitrary scaling)
            // e.g. 1 liter ~= 5 minutes of time value? Let's say 1L = 300 points
            let fuelScore = (fuel.liters * 300) * fuelWeight
            
            // Traffic score is implicit in time, but we can add penalty for high traffic factor
            let trafficPenalty = (fuel.trafficFactor - 1.0) * 1000 * trafficWeight
            
            let totalScore = timeScore + fuelScore + trafficPenalty
            
            analyzedRoutes.append((route, totalScore, fuel))
        }
        
        // 2. Sort by score (Lower is better)
        analyzedRoutes.sort { $0.score < $1.score }
        
        // 3. Categorize
        // Simplification:
        // - Best Score -> Balanced (Recommended)
        // - Lowest Time -> Fastest
        // - Lowest Fuel -> Fuel Saver
        
        guard let bestRoute = analyzedRoutes.first else { return [] }
        
        // Find Fastest
        let fastest = analyzedRoutes.min { $0.route.expectedTravelTime < $1.route.expectedTravelTime }!
        
        // Find Fuel Efficient
        let mostEfficient = analyzedRoutes.min { $0.fuel.liters < $1.fuel.liters }!
        
        var finalRoutes: [ScoredRoute] = []
        
        for analyzed in analyzedRoutes {
            var type: RouteType = .balanced
            
            // Determine type logic
            if analyzed.route === fastest.route {
                type = .fastest
            } else if analyzed.route === mostEfficient.route {
                type = .fuelEfficient
            }
            
            // Override if it's the absolute best score, we recommend it as Balanced (or whatever fits)
            // If Fastest IS ALSO the Best Score, it's just "Fastest & Recommended"
            // But UI separates them. Let's assign strictly.
            
            let isRecommended = (analyzed.route === bestRoute.route)
            
            // Refine naming: If recommended is same as fastest, call it Fastest.
            if isRecommended {
                if type == .fastest { type = .fastest }
                else if type == .fuelEfficient { type = .fuelEfficient }
                else { type = .balanced }
            }
            
            finalRoutes.append(ScoredRoute(
                route: analyzed.route,
                routeType: type,
                score: analyzed.score,
                fuelEstimate: analyzed.fuel,
                isRecommended: isRecommended
            ))
        }
        
        return finalRoutes
    }
}
