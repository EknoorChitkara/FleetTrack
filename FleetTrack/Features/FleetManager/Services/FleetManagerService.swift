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
    func addDriver(_ data: DriverCreationData) async throws {
        print("🚀 [addDriver] Starting driver creation for: \(data.fullName)")
        
        let temporaryPassword = generateTemporaryPassword()
        
        try await createUserViaGhostClient(
            email: data.email,
            password: temporaryPassword,
            fullName: data.fullName,
            phoneNumber: data.phoneNumber,
            role: "Driver",
            metadata: [
                "license_number": AnyJSON.string(data.licenseNumber),
                "address": AnyJSON.string(data.address)
            ]
        )
        
        print("✅ [addDriver] Driver created and invitation sent")
        print("🔑 [addDriver] Temporary Password: \(temporaryPassword)")
    }
    
    /// Add a new maintenance staff to the system
    func addMaintenanceStaff(_ data: MaintenanceStaffCreationData) async throws {
        print("🚀 [addMaintenanceStaff] Starting staff creation for: \(data.fullName)")
        
        let temporaryPassword = generateTemporaryPassword()
        
        try await createUserViaGhostClient(
            email: data.email,
            password: temporaryPassword,
            fullName: data.fullName,
            phoneNumber: data.phoneNumber,
            role: "Maintenance Personnel",
            metadata: [
                "specialization": AnyJSON.string(data.specialization),
                "years_of_experience": AnyJSON.string(data.yearsOfExperience)
            ]
        )
        
        print("✅ [addMaintenanceStaff] Maintenance staff created and invitation sent")
        print("🔑 [addMaintenanceStaff] Temporary Password: \(temporaryPassword)")
    }
    
    /// Creates a user using a secondary Supabase client with no persistence.
    /// This triggers the official Supabase invitation email automatically.
    private func createUserViaGhostClient(
        email: String,
        password: String,
        fullName: String,
        phoneNumber: String?,
        role: String,
        metadata: [String: AnyJSON] = [:]
    ) async throws {
        print("🔐 [GhostClient] Initializing isolated sign-up for: \(email)")
        
        let ghostClient = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    storage: NSLockingNoOpStorage(),
                    flowType: .implicit
                )
            )
        )
        
        do {
            // Check if user already exists - decode to array to check count correctly
            let response = try await client
                .from("users")
                .select("id")
                .eq("email", value: email)
                .execute()
            
            // PostgrestResponse.data is Data, [] is not empty Data.
            // We decode to see if we actually got records.
            struct UserRecord: Decodable { let id: UUID }
            let existingUsers = try? JSONDecoder().decode([UserRecord].self, from: response.data)
            
            if let existingUsers = existingUsers, !existingUsers.isEmpty {
                print("⚠️ User already exists in database. Sending a resend instead.")
                try await client.auth.resend(email: email, type: .signup)
                return
            }

            var fullMetadata: [String: AnyJSON] = [
                "full_name": AnyJSON.string(fullName),
                "role": AnyJSON.string(role),
                "phone_number": AnyJSON.string(phoneNumber ?? "")
            ]
            
            // Merge additional metadata
            for (key, value) in metadata {
                fullMetadata[key] = value
            }

            _ = try await ghostClient.auth.signUp(
                email: email,
                password: password,
                data: fullMetadata,
                redirectTo: URL(string: "fleettrack://auth/callback")
            )
            
            print("📧 [GhostClient] Invitation sent successfully via Implicit Flow for role: \(role).")
            
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
    
    /// Reassign a driver to a vehicle in the database
    func reassignDriver(vehicleId: UUID, driverId: UUID?) async throws {
        print("💾 [reassignDriver] Updating assignment for vehicle: \(vehicleId)")
        
        var driverName: String? = nil
        if let dId = driverId {
            let driver: FMDriver = try await client
                .from("drivers")
                .select()  // Select all columns so FMDriver can decode properly
                .eq("id", value: dId)
                .single()
                .execute()
                .value
            driverName = driver.fullName ?? driver.email ?? "Unknown"
        }
        
        let update: [String: AnyJSON] = [
            "assigned_driver_id": driverId != nil ? .string(driverId!.uuidString) : .null,
            "assigned_driver_name": driverName != nil ? .string(driverName!) : .null
        ]
        
        try await client
            .from("vehicles")
            .update(update)
            .eq("id", value: vehicleId)
            .execute()
            
        print("✅ [reassignDriver] Successfully updated vehicle \(vehicleId) in database")
    }
    
    /// Retire a vehicle and unassign its driver
    func retireVehicle(byId id: UUID) async throws {
        print("💾 [retireVehicle] Retiring vehicle: \(id)")
        
        let update: [String: AnyJSON] = [
            "status": .string("Retired"),
            "assigned_driver_id": .null,
            "assigned_driver_name": .null
        ]
        
        try await client
            .from("vehicles")
            .update(update)
            .eq("id", value: id)
            .execute()
            
        print("✅ [retireVehicle] Successfully retired vehicle \(id) in database")
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

    
    // MARK: - Service Management
    
    /// Send vehicle to service by creating maintenance tasks
    func sendVehicleToService(vehicleId: UUID, registrationNumber: String, serviceTypes: [String], description: String) async throws {
        print("🔧 ========== SENDING VEHICLE TO SERVICE ==========")
        print("🚗 Vehicle ID: \(vehicleId)")
        print("🚗 Registration: \(registrationNumber)")
        print("🛠️ Service Types: \(serviceTypes.joined(separator: ", "))")
        print("📝 Description: \(description)")
        print("📋 Tables to update: vehicles, maintenance_tasks")
        
        // 1. Update vehicle status to "Maintenance"
        print("")
        print("📤 Step 1/2: Updating vehicle status in 'vehicles' table...")
        let statusUpdate: [String: AnyJSON] = [
            "status": .string("Maintenance")
        ]
        
        do {
            try await client
                .from("vehicles")
                .update(statusUpdate)
                .eq("id", value: vehicleId)
                .execute()
            print("✅ Vehicle status updated to 'Maintenance'")
        } catch {
            print("❌ Failed to update vehicle status: \(error)")
            throw error
        }
        
        // 2. Create maintenance task for each service type
        print("")
        print("📤 Step 2/2: Creating maintenance tasks in 'maintenance_tasks' table...")
        
        for (index, serviceType) in serviceTypes.enumerated() {
            print("")
            print("   Task \(index + 1)/\(serviceTypes.count): \(serviceType)")
            
            // Map service type to MaintenanceComponent
            let component = mapServiceTypeToComponent(serviceType)
            let taskId = UUID()
            
            struct MaintenanceTaskInsert: Encodable {
                let id: UUID
                let vehicleId: UUID
                let vehicleRegistrationNumber: String
                let title: String  // Required field
                let component: String
                let priority: String
                let status: String
                let dueDate: Date
                let description: String?
                let taskType: String
                let createdAt: Date
                
                enum CodingKeys: String, CodingKey {
                    case id
                    case vehicleId = "vehicle_id"
                    case vehicleRegistrationNumber = "vehicle_registration_number"
                    case title
                    case component
                    case priority
                    case status
                    case dueDate = "due_date"
                    case description
                    case taskType = "task_type"
                    case createdAt = "created_at"
                }
            }
            
            let task = MaintenanceTaskInsert(
                id: taskId,
                vehicleId: vehicleId,
                vehicleRegistrationNumber: registrationNumber,
                title: "\(component) Service",  // Generate title from component
                component: component,
                priority: "Medium",  // Default priority
                status: "Pending",
                dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),  // Due in 7 days
                description: description.isEmpty ? nil : description,
                taskType: "Scheduled",
                createdAt: Date()
            )
            
            do {
                try await client
                    .from("maintenance_tasks")
                    .insert(task)
                    .execute()
                
                print("   ✅ Task created: ID \(taskId)")
                print("   📋 Table: maintenance_tasks")
                print("   🔩 Component: \(component)")
            } catch {
                print("   ❌ Failed to create task for \(serviceType): \(error)")
                // Continue with other tasks even if one fails
            }
        }
        
        print("")
        print("✅ ========== VEHICLE SERVICE COMPLETE ==========")
        print("✅ Vehicle \(registrationNumber) sent to service")
        print("✅ Created \(serviceTypes.count) maintenance task(s)")
        print("✅ All data saved to Supabase")
        print("🔧 =============================================")
    }
    
    /// Map service type string to MaintenanceComponent enum value
    private func mapServiceTypeToComponent(_ serviceType: String) -> String {
        switch serviceType {
        case "Engine":
            return "Engine"
        case "Oil", "Oil Change":
            return "Oil Change"
        case "Tires", "Tire Replacement":
            return "Tire Replacement"
        case "Brakes", "Brake Inspection":
            return "Brake Inspection"
        case "Battery":
            return "Battery"
        case "Transmission":
            return "Transmission"
        case "Suspension":
            return "Suspension"
        case "Electrical":
            return "Electrical"
        case "Cooling System":
            return "Cooling System"
        default:
            return "Other"
        }
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
    
    func fetchMaintenanceStaff() async throws -> [FMMaintenanceStaff] {
        let staff: [FMMaintenanceStaff] = try await client
            .from("maintenance_personnel")
            .select()
            .execute()
            .value
        return staff
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
