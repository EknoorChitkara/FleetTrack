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
    
    /// Sends an invitation email to the driver using Supabase Magic Link
    /// No Edge Function needed - uses built-in Supabase authentication
    private func sendDriverInvite(email: String, fullName: String) async throws {
        print("🔐 [sendDriverInvite] Starting invite for: \(email)")
        print("📧 [sendDriverInvite] Using Supabase Magic Link (no Edge Function)")
        
        do {
            // Send magic link invitation
            // This creates auth.users record and sends email automatically
            try await client.auth.signInWithOTP(
                email: email,
                redirectTo: URL(string: "fleettrack://set-password")!,
                shouldCreateUser: true
            )
            
            print("✅ [sendDriverInvite] Magic link sent to \(email)")
            print("📧 [sendDriverInvite] Driver will receive email with login link")
            print("ℹ️  [sendDriverInvite] Driver can use magic link to log in and set password")
            
        } catch {
            print("❌ [sendDriverInvite] Failed to send magic link: \(error)")
            print("   Error details: \(error.localizedDescription)")
            // Don't block driver creation if invite fails
            print("⚠️ [sendDriverInvite] Continuing without invite email")
        }
        
        print("🏁 [sendDriverInvite] Function completed")
    }
    
    // MARK: - Vehicle Management
    
    func addVehicle(_ data: VehicleCreationData) async throws {
        print("🚀 [addVehicle] Starting vehicle creation")
        print("   Registration: \(data.registrationNumber)")
        print("   Type: \(data.vehicleType)")
        print("   Assigned Driver ID: \(data.assignedDriverId?.uuidString ?? "nil")")
        
        // Fetch Driver Name if assigned
        var driverName: String? = nil
        if let driverId = data.assignedDriverId {
            do {
                // Specify columns to avoid PGRST116 error
                let driver: FMDriver = try await client
                    .from("drivers")
                    .select("id, full_name, email")
                    .eq("id", value: driverId)
                    .single()
                    .execute()
                    .value
                driverName = driver.fullName ?? driver.email ?? "Unknown"
                print("✅ Fetched driver name: \(driverName ?? "nil")")
            } catch {
                print("⚠️ Could not fetch driver name for vehicle assignment: \(error)")
                // Continue without driver name - vehicle creation should not fail
            }
        } else {
            print("ℹ️  No driver assigned to vehicle")
        }

        // Create insert DTO without status field - let database use default
        struct VehicleInsertDTO: Encodable {
            let id: UUID
            let registrationNumber: String
            let vehicleType: String  // Send as String to bypass enum validation
            let manufacturer: String
            let model: String
            let fuelType: String  // Send as String to bypass enum validation
            let capacity: String
            let registrationDate: Date
            // status field excluded - database will use default 'active'
            let assignedDriverId: UUID?
            let assignedDriverName: String?
            let vin: String?
            let mileage: Double?
            let insuranceStatus: String?
            let lastService: Date?
            let createdAt: Date
            
            enum CodingKeys: String, CodingKey {
                case id
                case registrationNumber = "registration_number"
                case vehicleType = "vehicle_type"
                case manufacturer
                case model
                case fuelType = "fuel_type"
                case capacity
                case registrationDate = "registration_date"
                case assignedDriverId = "assigned_driver_id"
                case assignedDriverName = "assigned_driver_name"
                case vin
                case mileage
                case insuranceStatus = "insurance_status"
                case lastService = "last_service"
                case createdAt = "created_at"
            }
        }
        
        let vehicleDTO = VehicleInsertDTO(
            id: UUID(),
            registrationNumber: data.registrationNumber,
            vehicleType: data.vehicleType.rawValue,  // Convert enum to String
            manufacturer: data.manufacturer,
            model: data.model,
            fuelType: data.fuelType.rawValue,  // Convert enum to String
            capacity: data.capacity,
            registrationDate: data.registrationDate,
            assignedDriverId: data.assignedDriverId,
            assignedDriverName: driverName,
            vin: nil,
            mileage: nil,
            insuranceStatus: nil,
            lastService: nil,
            createdAt: Date()
        )
        
        print("💾 [addVehicle] Inserting vehicle into database...")
        print("   Note: status field excluded, database will use default value")
        
        do {
            try await client
                .from("vehicles")
                .insert(vehicleDTO)
                .execute()
            
            print("✅ Vehicle record created: \(data.registrationNumber)")
            if let driverName = driverName {
                print("   Assigned to driver: \(driverName)")
            } else {
                print("   Status: Unassigned")
            }
        } catch {
            print("❌ [addVehicle] Failed to insert vehicle: \(error)")
            print("   Error type: \(type(of: error))")
            print("   Error description: \(error.localizedDescription)")
            throw error
        }
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
