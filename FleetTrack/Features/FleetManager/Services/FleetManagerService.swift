//
//  FleetManagerService.swift
//  FleetTrack
//
//  Created for Fleet Manager
//  Updated to match database schema
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
    /// 1. Sends invitation email via Edge Function (uses secret key)
    /// 2. Creates a record in the 'drivers' table
    func addDriver(_ data: DriverCreationData) async throws {
        print("🚀 [addDriver] Starting driver creation for: \(data.fullName)")
        print("📧 [addDriver] Email: \(data.email)")
        
        // Send invitation email via Edge Function
        // Uses secret key authentication (no JWT needed)
        try await sendDriverInvite(email: data.email, fullName: data.fullName)
        
        // Create Driver Record with all required fields
        let now = Date()
        let newDriver = FMDriver(
            id: UUID(),
            userId: nil, // Will be linked when driver sets password and logs in
            fullName: data.fullName,
            licenseNumber: data.licenseNumber,
            driverLicenseNumber: nil,
            phoneNumber: data.phoneNumber,
            email: data.email,
            address: data.address,
            status: data.status,
            isActive: true,
            createdAt: now,
            updatedAt: now
        )
        
        print("💾 [addDriver] Inserting driver record to database...")
        try await client
            .from("drivers")
            .insert(newDriver)
            .execute()
        
        print("✅ [addDriver] Driver record created successfully for \(data.fullName)")
    }
    
    /// Sends an invitation email to the driver using Supabase Edge Function
    /// Edge Function verifies user role internally (no secret key needed)
    private func sendDriverInvite(email: String, fullName: String) async throws {
        print("🔐 [sendDriverInvite] Starting invite for: \(email)")
        
        // Define the request body structure
        struct InviteRequest: Encodable {
            let email: String
            let fullName: String
            let role: String
        }
        
        // Define the response structure
        struct InviteResponse: Decodable {
            let success: Bool
            let userId: String?
            let message: String?
            let error: String?
        }
        
        let request = InviteRequest(email: email, fullName: fullName, role: "Driver")
        print("📦 [sendDriverInvite] Request payload: email=\(email), fullName=\(fullName), role=Driver")
        
        do {
            print("🌐 [sendDriverInvite] Calling Edge Function 'quick-function'...")
            
            // Call the Edge Function (no secret key needed - Edge Function verifies user internally)
            let response: InviteResponse = try await client.functions.invoke(
                "quick-function",
                options: FunctionInvokeOptions(body: request)
            )
            
            print("📥 [sendDriverInvite] Response received:")
            print("   - success: \(response.success)")
            print("   - userId: \(response.userId ?? "nil")")
            print("   - message: \(response.message ?? "nil")")
            print("   - error: \(response.error ?? "nil")")
            
            if response.success {
                print("📧 [sendDriverInvite] ✅ Invitation email sent to \(email)")
            } else if let error = response.error {
                print("❌ [sendDriverInvite] Failed to send invite: \(error)")
                throw NSError(domain: "FleetManager", code: 500, userInfo: [NSLocalizedDescriptionKey: error])
            }
        } catch {
            print("🚨 [sendDriverInvite] Error: \(error)")
            // Don't block driver creation if invite fails
            print("⚠️ [sendDriverInvite] Continuing without invite email")
        }
        
        print("🏁 [sendDriverInvite] Function completed")
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
                driverName = driver.fullName ?? driver.email ?? "Unknown"
            } catch {
                print("⚠️ Could not fetch driver name for vehicle assignment: \(error)")
            }
        }

        // Create FMVehicle from creation data - matches DB schema
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
            assignedDriverName: driverName,
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
        
        guard let driverId = data.driverId else {
            throw NSError(domain: "FleetManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Driver ID required"])
        }
        
        // Create trip matching DB schema
        let newTrip = FMTrip(
            id: UUID(),
            vehicleId: vehicleId,
            driverId: driverId,
            status: "Scheduled",
            startAddress: data.startAddress,
            endAddress: data.endAddress,
            distance: data.distance,
            startTime: data.startTime,
            purpose: data.purpose,
            createdAt: Date()
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
