//
//  DriverService.swift
//  FleetTrack
//
//  Created by FleetTrack on 09/01/26.
//

import Foundation
import Supabase

@MainActor
final class DriverService {
    
    static let shared = DriverService()
    
    private var client: SupabaseClient {
        supabase
    }
    
    private init() {}
    
    /// Fetch the driver profile linked to a user ID
    func getDriverProfile(userId: UUID) async throws -> Driver {
        let driver: Driver = try await client
            .from("drivers")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value
        return driver
    }
    
    /// Fetch the current vehicle assigned to the driver
    func getAssignedVehicle(vehicleId: UUID) async throws -> Vehicle {
        let vehicle: Vehicle = try await client
            .from("vehicles")
            .select()
            .eq("id", value: vehicleId.uuidString)
            .single()
            .execute()
            .value
        return vehicle
    }
    
    /// Fetch recent trips for the driver
    func getRecentTrips(driverId: UUID, limit: Int = 5) async throws -> [Trip] {
        let trips: [Trip] = try await client
            .from("trips")
            .select()
            .eq("driver_id", value: driverId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return trips
    }
    /// Fetch the count of completed trips for the driver
    func getCompletedTripsCount(driverId: UUID) async throws -> Int {
        let count = try await client
            .from("trips")
            .select("id", head: true, count: .exact)
            .eq("driver_id", value: driverId.uuidString)
            .eq("status", value: TripStatus.completed.rawValue)
            .execute()
            .count
        
        return count ?? 0
    }
    
    /// Fetch the total distance of completed trips for the driver
    func getCompletedTripsTotalDistance(driverId: UUID) async throws -> Double {
        struct TripDistance: Decodable {
            let distance: Double?
        }
        
        let trips: [TripDistance] = try await client
            .from("trips")
            .select("distance")
            .eq("driver_id", value: driverId.uuidString)
            .eq("status", value: TripStatus.completed.rawValue)
            .execute()
            .value
        
        let totalDistance = trips.compactMap { $0.distance }.reduce(0, +)
        return totalDistance
    }
    
    /// Update driver profile
    func updateDriverProfile<T: Encodable>(driverId: UUID, updates: T) async throws -> Driver {
        let updated: Driver = try await client
            .from("drivers")
            .update(updates)
            .eq("id", value: driverId.uuidString)
            .select()
            .single()
            .execute()
            .value
        return updated
    }
}
