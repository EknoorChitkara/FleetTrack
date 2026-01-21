//
//  FuelEstimationService.swift
//  FleetTrack
//
//  Estimated fuel consumption logic.
//

import Foundation
import CoreLocation

// MARK: - Fuel Estimation

struct FuelEstimate {
    let liters: Double
    let cost: Double // Optional: if we want to show cost later
    let trafficFactor: Double
}

class FuelEstimationService {
    static let shared = FuelEstimationService()
    
    private init() {}
    
    // Configurable average mileage (km/L)
    // In a real app, this would come from the Vehicle model.
    var defaultMileageKmPerLiter: Double = 15.0
    
    /// Calculate fuel estimation
    /// - Parameters:
    ///   - distanceMeters: Distance in meters
    ///   - expectedTravelTime: Expected travel time in seconds
    ///   - averageSpeedKmh: Optional average speed if pre-calculated, otherwise derived
    /// - Returns: FuelEstimate struct
    func estimateFuel(
        distanceMeters: Double,
        expectedTravelTime: TimeInterval
    ) -> FuelEstimate {
        
        // 1. Convert to usable units
        let distanceKm = distanceMeters / 1000.0
        let hours = expectedTravelTime / 3600.0
        
        // Avoid division by zero
        guard distanceKm > 0, hours > 0 else {
            return FuelEstimate(liters: 0, cost: 0, trafficFactor: 1.0)
        }
        
        // 2. Calculate average speed for this route
        let routeSpeedKmh = distanceKm / hours
        
        // 3. Determine Traffic Factor
        // Heuristic: Compare route speed to a "standard" free-flow speed (e.g., 60 km/h city, 80 km/h highway)
        // For simplicity, let's assume if speed is low, traffic is high.
        
        let trafficFactor: Double
        if routeSpeedKmh < 20 {
            // Heavy Traffic (Stop & Go)
            trafficFactor = 1.4
        } else if routeSpeedKmh < 40 {
            // Moderate Traffic
            trafficFactor = 1.2
        } else {
            // Low Traffic / Highway
            trafficFactor = 1.0
        }
        
        // 4. Calculate Base Fuel Used
        // Formula: (Distance / Mileage) * TrafficFactor
        let baseFuel = distanceKm / defaultMileageKmPerLiter
        let totalFuel = baseFuel * trafficFactor
        
        return FuelEstimate(
            liters: totalFuel,
            cost: 0, // Placeholder
            trafficFactor: trafficFactor
        )
    }
}
