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
        print("📧 [addDriver] Email: \(data.email)")
        
        // Generate password for the driver
        let temporaryPassword = generateTemporaryPassword()
        
        // Step 1: Create user in auth.users via RPC (email NOT confirmed)
        try await createUserViaRPC(
            email: data.email,
            password: temporaryPassword,
            fullName: data.fullName,
            role: "Driver",
            phoneNumber: data.phoneNumber,
            licenseNumber: data.licenseNumber,
            address: data.address
        )
        
        // Step 2: Send verification email using Supabase OTP
        try await sendVerificationEmail(email: data.email)
        
        print("✅ [addDriver] Driver created in auth.users")
        print("📧 [addDriver] Verification email sent to \(data.email)")
        print("🔑 [addDriver] Temporary Password: \(temporaryPassword)")
        print("⚠️ [addDriver] IMPORTANT: Share this password with the driver securely!")
        print("ℹ️  [addDriver] Flow: Driver verifies email → public.users → drivers table created automatically")
    }
    
    /// Creates a user in auth.users via the Supabase RPC database function
    /// Email is NOT confirmed - user must verify via email link first
    private func createUserViaRPC(
        email: String,
        password: String,
        fullName: String,
        role: String,
        phoneNumber: String?,
        licenseNumber: String? = nil,
        address: String? = nil
    ) async throws {
        print("🔐 [createUserViaRPC] Calling RPC function for: \(email)")
        
        let params: [String: AnyJSON] = [
            "p_email": .string(email),
            "p_password": .string(password),
            "p_full_name": .string(fullName),
            "p_role": .string(role),
            "p_phone_number": .string(phoneNumber ?? ""),
            "p_license_number": .string(licenseNumber ?? ""),
            "p_address": .string(address ?? "")
        ]
        
        // 1. Create the user in auth.users via RPC
        do {
            let response = try await client
                .rpc("create_fleet_user_rpc", params: params)
                .execute()
            
            let data = response.data
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let success = json["success"] as? Bool, success else {
                let error = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
                throw NSError(domain: "FleetManager", code: 400, userInfo: [NSLocalizedDescriptionKey: error ?? "Failed to create user"])
            }
            
            print("✅ [createUserViaRPC] User created in database")
            
            // 2. Trigger the invitation email using resendu
            do {
                try await client.auth.resend(
                    email: email,
                    type: .signup
                )
                print("📧 [createUserViaRPC] Invitation email triggered successfully")
            } catch {
                let errorMsg = error.localizedDescription
                if errorMsg.contains("rate_limit") || errorMsg.contains("59 seconds") {
                    print("⚠️ [createUserViaRPC] User created, but email rate limited. Driver will need a manual resend in 1 minute.")
                    // Don't throw - the user is already created, which is the main part.
                } else {
                    print("❌ [createUserViaRPC] Failed to send email: \(errorMsg)")
                    throw error
                }
            }
            
        } catch {
            print("❌ [createUserViaRPC] Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // sendVerificationEmail is no longer needed as signUp handles it
    private func sendVerificationEmail(email: String) async throws {
        // No-op: signUp already sent the email
    }
    
    /// Generates a temporary password for the new user
    private func generateTemporaryPassword() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%"
        return String((0..<16).map { _ in characters.randomElement()! })
        return String((0..<16).map { _ in characters.randomElement()! })
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
