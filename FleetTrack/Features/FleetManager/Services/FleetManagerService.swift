//
//  FleetManagerService.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import Foundation
import Supabase

class FleetManagerService {
    static let shared = FleetManagerService()
    
    // Access the global Supabase client
    private var client: SupabaseClient {
        SupabaseClientManager.shared.client
    }
    
    private init() {}
    
    // MARK: - Driver Management
    
    /// Add a new driver to the system
    /// 1. Sends an invitation email (Magic Link)
    /// 2. Creates a record in the 'drivers' table
    func addDriver(_ data: DriverCreationData) async throws {
        // 1. Invite User via Email (Magic Link)
        // This sends an email to the user with a login link.
        // If the user doesn't exist, it effectively acts as a signup invite if signups are enabled.
        // Note: For a strict "Invite" flow, we might want to check if user exists first, 
        // but signInWithOTP is safe and idempotent for this use case.
        // We MUST specify the redirect URL to ensure it opens the app
        try await client.auth.signInWithOTP(
            email: data.email,
            redirectTo: URL(string: "fleettrack://login-callback")!
        )
        print("📧 Invitation sent to \(data.email)")
        
        // 2. Create Driver Record
        // ... (rest of addDriver remains same)
        let newDriver = FMDriver(
            id: UUID(),
            fullName: data.fullName,
            licenseNumber: data.licenseNumber,
            phoneNumber: data.phoneNumber,
            email: data.email,
            address: data.address,
            status: data.status,
            createdAt: Date()
        )
        
        try await client
            .from("drivers")
            .insert(newDriver)
            .execute()
        
        print("✅ Driver record created for \(data.fullName)")
    }
    
    // MARK: - Vehicle Management
    
    func addVehicle(_ data: VehicleCreationData) async throws {
        // Fetch Driver Name if assigned
        var driverName: String? = nil
        if let driverId = data.assignedDriverId {
            do {
                let driver: FMDriver = try await client
                    .from("drivers")
                    .select()
                    .eq("id", value: driverId)
                    .single()
                    .execute()
                    .value
                driverName = driver.fullName
            } catch {
                print("⚠️ Could not fetch driver name for vehicle assignment: \(error)")
            }
        }

        // Create FMVehicle from creation data
        let newVehicle = FMVehicle(
            id: UUID(),
            registrationNumber: data.registrationNumber,
            vehicleType: data.vehicleType,
            manufacturer: data.manufacturer,
            model: data.model,
            fuelType: data.fuelType,
            capacity: data.capacity,
            registrationDate: data.registrationDate,
            status: data.status,
            assignedDriverId: data.assignedDriverId,
            assignedDriverName: driverName, // Populated from DB fetch
            createdAt: Date()
        )
        
        try await client
            .from("vehicles")
            .insert(newVehicle)
            .execute()
            
        print("✅ Vehicle record created: \(data.registrationNumber)")
    }
    
    // MARK: - Trip Management
    
    func addTrip(_ data: TripCreationData) async throws {
        guard let vehicleId = data.vehicleId else {
            throw NSError(domain: "FleetManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Vehicle ID required"])
        }
        
        // Fetch Vehicle Name
        var vehicleName = "Unknown Vehicle"
        do {
            let vehicle: FMVehicle = try await client
                .from("vehicles")
                .select()
                .eq("id", value: vehicleId)
                .single()
                .execute()
                .value
            vehicleName = vehicle.registrationNumber
        } catch {
             print("⚠️ Could not fetch vehicle name for trip: \(error)")
        }
        
        let newTrip = FMTrip(
            id: UUID(),
            vehicleId: vehicleId,
            vehicleName: vehicleName, // Populated from DB fetch
            startLocation: data.startLocation,
            destination: data.destination,
            distance: data.distance,
            startDate: data.startDate,
            startTime: data.startTime,
            status: "Scheduled"
        )
        
        try await client
            .from("trips")
            .insert(newTrip)
            .execute()
            
        print("✅ Trip record created")
    }

    
    // MARK: - Fetch Data
    
    func fetchVehicles() async throws -> [FMVehicle] {
        let vehicles: [FMVehicle] = try await client
            .from("vehicles")
            .select()
            .execute()
            .value
        return vehicles
    }
    
    func fetchDrivers() async throws -> [FMDriver] {
        let drivers: [FMDriver] = try await client
            .from("drivers")
            .select()
            .execute()
            .value
        return drivers
    }
    
    func fetchTrips() async throws -> [FMTrip] {
        let trips: [FMTrip] = try await client
            .from("trips")
            .select()
            .execute()
            .value
        return trips
    }
}
