//
//  FuelTrackingService.swift
//  FleetTrack
//
//  Created for managing fuel refill logs and efficiency updates
//

import Foundation
import Supabase

class FuelTrackingService {
    static let shared = FuelTrackingService()
    
    private init() {}
    
    // MARK: - Refill Logging
    
    /// Log a fuel refill event
    func addRefill(
        tripId: UUID,
        vehicleId: UUID,
        driverId: UUID,
        liters: Double,
        cost: Double?,
        odometer: Double?,
        receiptUrl: String?,
        gaugeUrl: String?,
        location: (lat: Double, long: Double)?
    ) async throws -> FuelRefill {
        
        let refill = FuelRefill(
            tripId: tripId,
            vehicleId: vehicleId,
            driverId: driverId,
            fuelAddedLiters: liters,
            fuelCost: cost,
            odometerReading: odometer,
            fuelGaugePhotoUrl: gaugeUrl,
            receiptPhotoUrl: receiptUrl,
            locationLatitude: location?.lat,
            locationLongitude: location?.long
        )
        
        // 1. Insert refill record
        let loggedRefill: FuelRefill = try await supabase
            .from("fuel_refills")
            .insert(refill)
            .select()
            .single()
            .execute()
            .value
        
        print("✅ Refill logged: \(loggedRefill.id)")
        return loggedRefill
    }
    
    /// Fetch all refills for a specific trip
    func fetchTripRefills(tripId: UUID) async throws -> [FuelRefill] {
        let refills: [FuelRefill] = try await supabase
            .from("fuel_refills")
            .select()
            .eq("trip_id", value: tripId)
            .order("timestamp", ascending: true)
            .execute()
            .value
        
        return refills
    }
    
    // MARK: - Efficiency Updates
    
    /// Update vehicle's standard efficiency based on new trip data
    /// This uses a moving average to smooth out variations
    func updateVehicleEfficiency(
        vehicleId: UUID,
        newEfficiency: Double
    ) async throws {
        guard newEfficiency > 0, newEfficiency < 50 else { return } // Sanity check (0-50 km/L)
        
        // 1. Get current vehicle details
        let vehicle: Vehicle = try await supabase
            .from("vehicles")
            .select()
            .eq("id", value: vehicleId)
            .single()
            .execute()
            .value
        
        // 2. Calculate new average (weighted 80% old, 20% new)
        let currentEfficiency = vehicle.standardFuelEfficiency ?? newEfficiency
        let updatedEfficiency = (currentEfficiency * 0.8) + (newEfficiency * 0.2)
        
        // 3. Update vehicle
        try await supabase
            .from("vehicles")
            .update(["standard_fuel_efficiency": updatedEfficiency])
            .eq("id", value: vehicleId)
            .execute()
            
        print("✅ Vehicle efficiency updated to \(String(format: "%.2f", updatedEfficiency)) km/L")
    }
}
