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
    func getRecentTrips(driverId: UUID, limit: Int = 2) async throws -> [Trip] {
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
    
    /// Fetch the next scheduled trip for the driver (limit 1)
    func getNextScheduledTrip(driverId: UUID) async throws -> Trip? {
        let trips: [Trip] = try await client
            .from("trips")
            .select()
            .eq("driver_id", value: driverId.uuidString)
            .eq("status", value: TripStatus.scheduled.rawValue)
            .order("start_time", ascending: true) // Closest start time first
            .limit(1)
            .execute()
            .value
        return trips.first
    }
    
    /// Fetch the current ongoing trip for the driver (limit 1)
    func getOngoingTrip(driverId: UUID) async throws -> Trip? {
        let trips: [Trip] = try await client
            .from("trips")
            .select()
            .eq("driver_id", value: driverId.uuidString)
            .eq("status", value: TripStatus.ongoing.rawValue)
            .limit(1)
            .execute()
            .value
        return trips.first
    }
    
    /// Calculate driver statistics from completed trips
    func getDriverStats(driverId: UUID) async throws -> (totalDistance: Double, totalDuration: TimeInterval, tripCount: Int) {
        struct TripStat: Decodable {
            let distance: Double?
            let start_time: Date?
            let end_time: Date?
        }
        
        let trips: [TripStat] = try await client
            .from("trips")
            .select("distance, start_time, end_time")
            .eq("driver_id", value: driverId.uuidString)
            .eq("status", value: TripStatus.completed.rawValue)
            .execute()
            .value
        
        let totalDistance = trips.compactMap { $0.distance }.reduce(0, +)
        let totalDuration = trips.reduce(0) { result, trip in
            guard let start = trip.start_time, let end = trip.end_time else { return result }
            return result + end.timeIntervalSince(start)
        }
        
        return (totalDistance, totalDuration, trips.count)
    }
    
    /// Fetch the count of completed trips for the driver
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
