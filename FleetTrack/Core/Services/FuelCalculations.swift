//
//  FuelCalculations.swift
//  FleetTrack
//
//  Created for calculating fuel efficiency and consumption
//

import Foundation

struct FuelConsumptionResult {
    let litersConsumed: Double
    let efficiencyKmPerLiter: Double
    let costPerKm: Double?
}

class FuelCalculationService {
    static let shared = FuelCalculationService()
    
    private init() {}
    
    /// Calculate fuel consumption based on sensor readings (Start % - End % + Refills)
    /// - Parameters:
    ///   - startPercentage: 0-100
    ///   - endPercentage: 0-100
    ///   - tankCapacity: in Liters
    ///   - refills: Liters added during trip
    func calculateSensorBasedConsumption(
        startPercentage: Double,
        endPercentage: Double,
        tankCapacity: Double,
        refills: [FuelRefill]
    ) -> Double {
        let startLiters = (startPercentage / 100.0) * tankCapacity
        let endLiters = (endPercentage / 100.0) * tankCapacity
        
        let totalRefilledLiters = refills.reduce(0) { $0 + $1.fuelAddedLiters }
        
        // Consumed = Start + Refilled - End
        let consumed = startLiters + totalRefilledLiters - endLiters
        
        return max(0, consumed) // Prevent negative values
    }
    
    /// Calculate expected consumption based on odometer and standard efficiency
    /// - Parameters:
    ///   - distanceKm: Distance driven
    ///   - standardEfficiency: km per liter
    func calculateOdometerBasedConsumption(
        distanceKm: Double,
        standardEfficiency: Double
    ) -> Double {
        guard standardEfficiency > 0 else { return 0 }
        return distanceKm / standardEfficiency
    }
    
    /// Calculate efficiency for the current trip (km/L)
    func calculateTripEfficiency(
        distanceKm: Double,
        consumedLiters: Double
    ) -> Double {
        guard consumedLiters > 0 else { return 0 }
        return distanceKm / consumedLiters
    }
    
    /// Validate if vehicle has enough fuel for the trip + safety margin
    /// - Parameters:
    ///   - distanceKm: Trip distance
    ///   - currentFuelLiters: Current fuel in tank
    ///   - standardEfficiency: Vehicle's efficiency (km/L)
    ///   - safetyMarginLiters: Reserve fuel (default 15L)
    /// - Returns: Tuple (canComplete, missingLiters)
    func validateTripFuel(
        distanceKm: Double,
        currentFuelLiters: Double,
        standardEfficiency: Double,
        safetyMarginLiters: Double = 15.0
    ) -> (canComplete: Bool, missingLiters: Double) {
        let requiredLiters = (distanceKm / standardEfficiency) + safetyMarginLiters
        
        if currentFuelLiters >= requiredLiters {
            return (true, 0)
        } else {
            return (false, requiredLiters - currentFuelLiters)
        }
    }
    
    /// Compare sensor vs odometer calculations to detect anomalies (theft/leak/sensor error)
    /// - Returns: Percentage difference (positive means sensor reported more usage than expected)
    func compareCalculations(
        sensorConsumed: Double,
        odometerExpected: Double
    ) -> Double {
        guard odometerExpected > 0 else { return 0 }
        return ((sensorConsumed - odometerExpected) / odometerExpected) * 100
    }
}
