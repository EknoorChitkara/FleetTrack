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
    /// Flow:
    /// 1. Create user in auth.users via RPC database function (NOT confirmed)
    /// 2. Send verification email to the driver
    /// 3. Driver clicks verification link in email
    /// 4. Trigger syncs to public.users → drivers table
    /// 5. Driver can now login with their password
    func addDriver(_ data: DriverCreationData) async throws {
        print("🚀 [addDriver] Starting driver creation for: \(data.fullName)")
        
        // Generate password for the driver
        let temporaryPassword = generateTemporaryPassword()
        
        // Step 1: Create user via Ghost Client (Standard Auth flow)
        try await createUserViaGhostClient(
            email: data.email,
            password: temporaryPassword,
            fullName: data.fullName,
            phoneNumber: data.phoneNumber,
            licenseNumber: data.licenseNumber,
            address: data.address
        )
        
        print("✅ [addDriver] Driver created and invitation sent")
        print("🔑 [addDriver] Temporary Password: \(temporaryPassword)")
        print("⚠️ [addDriver] IMPORTANT: Share this password with the driver securely!")
    }
    
    /// Creates a user using a secondary Supabase client with no persistence.
    /// This triggers the official Supabase invitation email automatically.
    private func createUserViaGhostClient(
        email: String,
        password: String,
        fullName: String,
        phoneNumber: String?,
        role: String = "Driver",
        licenseNumber: String? = nil,
        address: String? = nil,
        specializations: String? = nil
    ) async throws {
        print("🔐 [GhostClient] Initializing isolated sign-up for: \(email)")
        
        // 1. Create a "Ghost" client with PKCE DISABLED
        // PKCE is great for security but causes 'bad_code_verifier' when 
        // one client starts a signup and another finishes it.
        let ghostClient = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    storage: NSLockingNoOpStorage(),
                    flowType: .implicit // Uses stable tokens in URL instead of PKCE
                )
            )
        )
        
        // 2. Perform a standard signUp
        do {
            // Check if user already exists to avoid duplicate trigger
            let existingUsers: [FMDriver] = try await client
                .from("drivers")
                .select()
                .eq("email", value: email)
                .execute()
                .value
            
            if !existingUsers.isEmpty {
                print("⚠️ User already exists. Sending a resend instead.")
                try await client.auth.resend(email: email, type: .signup)
                return
            }

            var metadata: [String: AnyJSON] = [
                "full_name": AnyJSON.string(fullName),
                "role": AnyJSON.string(role),
                "phone_number": AnyJSON.string(phoneNumber ?? "")
            ]
            
            // Add role-specific metadata
            if role == "Driver" {
                metadata["license_number"] = AnyJSON.string(licenseNumber ?? "")
                metadata["address"] = AnyJSON.string(address ?? "")
            } else if role == "Maintenance Personnel", let specs = specializations {
                // specializations is already a comma-separated string
                metadata["specializations"] = AnyJSON.string(specs)
            }
            
            _ = try await ghostClient.auth.signUp(
                email: email,
                password: password,
                data: metadata,
                redirectTo: URL(string: "fleettrack://auth/callback")
            )
            
            print("📧 [GhostClient] Invitation sent successfully via Implicit Flow.")
            
        } catch {
            print("❌ [GhostClient] failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// A simple storage class that does nothing
    private class NSLockingNoOpStorage: @unchecked Sendable, AuthLocalStorage {
        func store(key: String, value: Data) throws {}
        func retrieve(key: String) throws -> Data? { return nil }
        func remove(key: String) throws {}
    }
    
    /// Generates a temporary password for the new user
    private func generateTemporaryPassword() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%"
        return String((0..<16).map { _ in characters.randomElement()! })
    }
    
    // MARK: - Maintenance Personnel Management
    
    /// Add a new maintenance user to the system
    /// Flow:
    /// 1. Create user in auth.users via Ghost Client
    /// 2. Send verification email to the user
    /// 3. User clicks verification link in email
    /// 4. Trigger syncs to maintenance_personnel table
    /// 5. User can now login with their password
    func addMaintenanceUser(_ data: MaintenanceCreationData) async throws {
        print("🚀 [addMaintenanceUser] Starting maintenance user creation for: \(data.fullName)")
        
        // Generate password for the user
        let temporaryPassword = generateTemporaryPassword()
        
        // Step 1: Create user via Ghost Client
        try await createUserViaGhostClient(
            email: data.email,
            password: temporaryPassword,
            fullName: data.fullName,
            phoneNumber: data.phoneNumber,
            role: "Maintenance Personnel",
            specializations: data.specializations
        )
        
        print("✅ [addMaintenanceUser] User created and invitation sent")
        print("🔑 [addMaintenanceUser] Temporary Password: \(temporaryPassword)")
        print("⚠️ [addMaintenanceUser] IMPORTANT: Share this password with the user securely!")
    }
    
    // MARK: - Vehicle Management
    
    func addVehicle(_ data: VehicleCreationData, id: UUID? = nil) async throws {
        print("🚀 [addVehicle] Starting vehicle creation")
        print("   Registration: \(data.registrationNumber)")
        print("   Type: \(data.vehicleType)")
        print("   Assigned Driver ID: \(data.assignedDriverId?.uuidString ?? "nil")")
        
        // Use provided ID or generate a new one
        let vehicleId = id ?? UUID()
        
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
            id: vehicleId,
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
        
        // Create DTO matching trips table schema (with lat/lon)
        struct TripInsertDTO: Encodable {
            let id: UUID
            let vehicleId: UUID
            let driverId: UUID
            let status: String
            let startAddress: String?
            let endAddress: String?
            let startLatitude: Double?
            let startLongitude: Double?
            let endLatitude: Double?
            let endLongitude: Double?
            let distance: Double?
            let startTime: Date?
            let purpose: String?
            let createdAt: Date
            
            enum CodingKeys: String, CodingKey {
                case id
                case vehicleId = "vehicle_id"
                case driverId = "driver_id"
                case status
                case startAddress = "start_address"
                case endAddress = "end_address"
                case startLatitude = "start_latitude"
                case startLongitude = "start_longitude"
                case endLatitude = "end_latitude"
                case endLongitude = "end_longitude"
                case distance
                case startTime = "start_time"
                case purpose
                case createdAt = "created_at"
            }
        }
        
        let tripDTO = TripInsertDTO(
            id: UUID(),
            vehicleId: vehicleId,
            driverId: driverId,
            status: "Scheduled",
            startAddress: data.startAddress,
            endAddress: data.endAddress,
            startLatitude: data.startLatitude,
            startLongitude: data.startLongitude,
            endLatitude: data.endLatitude,
            endLongitude: data.endLongitude,
            distance: data.distance,
            startTime: data.startTime,
            purpose: data.purpose,
            createdAt: Date()
        )
        
        try await client
            .from("trips")
            .insert(tripDTO)
            .execute()
            
        print("✅ Trip record created with coordinates")
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
    
    
    func fetchMaintenancePersonnel() async throws -> [MaintenancePersonnel] {
        let personnel: [MaintenancePersonnel] = try await client
            .from("maintenance_personnel")
            .select()
            .execute()
            .value
        return personnel
    }
    
    // MARK: - Delete Maintenance Personnel
    
    func deleteMechanic(byId id: UUID) async throws {
        print("🗑️ [deleteMechanic] Deleting mechanic with ID: \(id)")
        
        // Step 1: Fetch the mechanic to get user_id
        let mechanic: MaintenancePersonnel = try await client
            .from("maintenance_personnel")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        
        guard let userId = mechanic.userId else {
            print("⚠️ [deleteMechanic] No user_id found, deleting only from maintenance_personnel")
            // If no user_id, just delete from maintenance_personnel
            try await client
                .from("maintenance_personnel")
                .delete()
                .eq("id", value: id)
                .execute()
            return
        }
        
        print("ℹ️ [deleteMechanic] Found user_id: \(userId)")
        
        // Step 2: Delete from auth.users (parent) via Edge Function
        // This will CASCADE to maintenance_personnel automatically
        let response = try await client.functions.invoke(
            "delete-user",
            options: FunctionInvokeOptions(
                body: ["userId": userId.uuidString]
            )
        )
        
        print("✅ [deleteMechanic] Auth user deleted, CASCADE will remove maintenance_personnel record")
    }
}
