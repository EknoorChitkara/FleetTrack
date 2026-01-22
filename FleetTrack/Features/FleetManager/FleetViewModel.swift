import Foundation
import SwiftUI
import Combine

class FleetViewModel: ObservableObject {
    @Published var vehicles: [FMVehicle] = []
    @Published var drivers: [FMDriver] = []
    @Published var maintenanceStaff: [FMMaintenanceStaff] = []
    @Published var trips: [FMTrip] = []
    @Published var activities: [FMActivity] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Singleton for easy access across views
    static let shared = FleetViewModel()
    
    private init() {
        Task { await loadData() }
    }
    
    @MainActor
    func loadData() async {
        isLoading = true
        do {
            async let fetchedVehicles = FleetManagerService.shared.fetchVehicles()
            async let fetchedDrivers = FleetManagerService.shared.fetchDrivers()
            async let fetchedMaintenance = FleetManagerService.shared.fetchMaintenanceStaff()
            async let fetchedTrips = FleetManagerService.shared.fetchTrips()
            
            self.vehicles = try await fetchedVehicles
            self.drivers = try await fetchedDrivers
            self.maintenanceStaff = try await fetchedMaintenance
            self.trips = try await fetchedTrips
            
            self.isLoading = false
            print("✅ Fleet Data Loaded: \(vehicles.count) vehicles, \(drivers.count) drivers")
        } catch {
            self.errorMessage = "Failed to load fleet data: \(error.localizedDescription)"
            self.isLoading = false
            print("❌ Error loading fleet data: \(error)")
        }
    }
    
    // MARK: - Actions
    
    func addVehicle(_ data: VehicleCreationData) {
        let vehicleId = UUID() // Pre-generate ID for sync
        
        // 1. Optimistic Update (Immediate UI Reflection)
        let newVehicle = FMVehicle(
            id: vehicleId,
            registrationNumber: data.registrationNumber,
            vehicleType: data.vehicleType,
            manufacturer: data.manufacturer,
            model: data.model,
            fuelType: data.fuelType,
            capacity: data.capacity,
            registrationDate: data.registrationDate,
            status: .active, // Defaulting to active as requested to remove from form
            assignedDriverId: data.assignedDriverId,
            assignedDriverName: getDriverName(for: data.assignedDriverId),
            tankCapacity: Double(data.tankCapacity)
        )
        
        vehicles.append(newVehicle)
        
        // 2. Optimistically update driver status
        if let driverId = data.assignedDriverId, 
           let dIndex = drivers.firstIndex(where: { $0.id == driverId }) {
            drivers[dIndex].status = .onTrip
        }
        
        print("🚀 [FleetViewModel] Optimistically added vehicle: \(data.registrationNumber)")
        
        // 3. Perform Backend Call
        Task { @MainActor in
            do {
                try await FleetManagerService.shared.addVehicle(data, id: vehicleId)
                self.logActivity(title: "New Vehicle Added", description: "Vehicle \(data.registrationNumber) was added to fleet.", icon: "car.fill", color: "blue")
            } catch {
                // 4. Rollback on failure
                self.vehicles.removeAll(where: { $0.id == vehicleId })
                if let driverId = data.assignedDriverId, 
                   let dIndex = self.drivers.firstIndex(where: { $0.id == driverId }) {
                    self.drivers[dIndex].status = .available
                }
                self.errorMessage = "Failed to add vehicle: \(error.localizedDescription)"
                print("❌ [FleetViewModel] Failed to add vehicle, rolled back: \(error)")
            }
        }
    }
    
    func addDriver(_ data: DriverCreationData) {
        isLoading = true
        Task { @MainActor in
            do {
                try await FleetManagerService.shared.addDriver(data)
                
                // Optimistically update UI with the new driver
                let now = Date()
                let newDriver = FMDriver(
                    id: UUID(),
                    userId: nil,
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
                self.drivers.append(newDriver)
                self.logActivity(title: "New Driver Invited", description: "Invitation sent to \(data.email).", icon: "envelope.fill", color: "green")
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to add driver: \(error.localizedDescription)"
                self.isLoading = false
                print("Error adding driver: \(error)")
            }
        }
    }
    
    func addTrip(_ data: TripCreationData) {
        isLoading = true
        Task { @MainActor in
            do {
                try await FleetManagerService.shared.addTrip(data)
                
                // Optimistic UI Update - Updated to match new FMTrip model
                let newTrip = FMTrip(
                    id: UUID(),
                    vehicleId: data.vehicleId ?? UUID(),
                    driverId: data.driverId ?? UUID(),
                    status: "Scheduled",
                    startAddress: data.startAddress,
                    endAddress: data.endAddress,
                    distance: data.distance,
                    startTime: data.startTime,
                    purpose: data.purpose
                )
                self.trips.append(newTrip)
                self.logActivity(title: "New Trip Scheduled", description: "Trip to \(data.endAddress) created.", icon: "map.fill", color: "orange")
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to add trip: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func addMaintenanceStaff(_ data: MaintenanceStaffCreationData) {
        isLoading = true
        Task { @MainActor in
            do {
                try await FleetManagerService.shared.addMaintenanceStaff(data)
                
                // Optimistically update UI with the new staff member
                let now = Date()
                let newStaff = FMMaintenanceStaff(
                    id: UUID(),
                    userId: nil,
                    fullName: data.fullName,
                    email: data.email,
                    phoneNumber: data.phoneNumber,
                    specialization: data.specialization,
                    yearsOfExperience: Int(data.yearsOfExperience),
                    status: "Available",
                    isActive: true,
                    createdAt: now,
                    updatedAt: now
                )
                // If you had a list of maintenance staff in the VM, you would append it here
                self.maintenanceStaff.append(newStaff) 
                
                self.logActivity(
                    title: "Staff Invited",
                    description: "Invitation sent to \(data.email).",
                    icon: "wrench.and.screwdriver.fill",
                    color: "orange"
                )
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to add maintenance staff: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ [FleetViewModel] Failed to add staff: \(error)")
            }
        }
    }
    
    func deleteVehicle(at offsets: IndexSet) {
        vehicles.remove(atOffsets: offsets)
    }
    
    func deleteVehicle(byId id: UUID) {
        if let registration = vehicles.first(where: { $0.id == id })?.registrationNumber {
            vehicles.removeAll(where: { $0.id == id })
            logActivity(title: "Vehicle Removed", description: "Vehicle \(registration) was removed from fleet.", icon: "trash.fill", color: "red")
        }
    }
    
    func deleteDriver(byId id: UUID) {
        if let driverName = drivers.first(where: { $0.id == id })?.displayName {
            drivers.removeAll(where: { $0.id == id })
            logActivity(title: "Driver Removed", description: "Driver \(driverName) was removed from fleet.", icon: "person.fill.badge.minus", color: "red")
        }
    }
    
    func reassignDriver(vehicleId: UUID, driverId: UUID?) {
        isLoading = true
        Task { @MainActor in
            do {
                // 1. Perform database update
                try await FleetManagerService.shared.reassignDriver(vehicleId: vehicleId, driverId: driverId)
                
                // 2. Update local state
                if let index = vehicles.firstIndex(where: { $0.id == vehicleId }) {
                    let oldDriverId = vehicles[index].assignedDriverId
                    
                    // Update vehicle
                    vehicles[index].assignedDriverId = driverId
                    vehicles[index].assignedDriverName = getDriverName(for: driverId)
                    
                    // Update old driver status to available
                    if let oldId = oldDriverId, let dIndex = drivers.firstIndex(where: { $0.id == oldId }) {
                        drivers[dIndex].status = .available
                    }
                    
                    // Update new driver status to onTrip (Assigned)
                    if let newId = driverId, let dIndex = drivers.firstIndex(where: { $0.id == newId }) {
                        drivers[dIndex].status = .onTrip
                    }
                    
                    let driverName = vehicles[index].assignedDriverName ?? "Unassigned"
                    logActivity(title: "Driver Reassigned", description: "Vehicle \(vehicles[index].registrationNumber) assigned to \(driverName).", icon: "person.badge.plus.fill", color: "green")
                }
                isLoading = false
            } catch {
                self.errorMessage = "Failed to reassign driver: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ [FleetViewModel] Reassign failed: \(error)")
            }
        }
    }
    
    func markForService(vehicleId: UUID, serviceTypes: [String], description: String = "") {
        isLoading = true
        Task { @MainActor in
            do {
                if let index = vehicles.firstIndex(where: { $0.id == vehicleId }) {
                    let registrationNumber = vehicles[index].registrationNumber
                    
                    print("🚀 [FleetViewModel] Sending vehicle to service...")
                    print("   Vehicle: \(registrationNumber)")
                    print("   Services: \(serviceTypes.joined(separator: ", "))")
                    
                    // Call FleetManagerService to persist to database
                    try await FleetManagerService.shared.sendVehicleToService(
                        vehicleId: vehicleId,
                        registrationNumber: registrationNumber,
                        serviceTypes: serviceTypes,
                        description: description
                    )
                    
                    // Update local UI state
                    vehicles[index].status = .inMaintenance
                    vehicles[index].lastService = Date()
                    vehicles[index].maintenanceServices = serviceTypes
                    vehicles[index].maintenanceDescription = description
                    
                    // Create and append log
                    let newLog = MaintenanceLog(
                        date: Date(),
                        serviceTypes: serviceTypes,
                        description: description
                    )
                    
                    if vehicles[index].maintenanceLogs == nil {
                        vehicles[index].maintenanceLogs = []
                    }
                    vehicles[index].maintenanceLogs?.insert(newLog, at: 0) // Newest first
                    
                    let services = serviceTypes.joined(separator: ", ")
                    let logDescription = description.isEmpty ? "Vehicle \(registrationNumber) sent for \(services)." : "Vehicle \(registrationNumber) sent for \(services). Notes: \(description)"
                    logActivity(title: "Service Scheduled", description: logDescription, icon: "wrench.and.screwdriver.fill", color: "orange")
                    
                    print("✅ [FleetViewModel] Service scheduled successfully")
                }
                isLoading = false
            } catch {
                print("❌ ============================================")
                print("❌ ERROR in FleetViewModel.markForService")
                print("❌ Vehicle ID: \(vehicleId)")
                print("❌ Services: \(serviceTypes.joined(separator: ", "))")
                print("❌ Error: \(error.localizedDescription)")
                print("❌ Full Error: \(error)")
                print("❌ ============================================")
                
                self.errorMessage = "Failed to schedule service: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func retireVehicle(byId id: UUID) {
        isLoading = true
        Task { @MainActor in
            do {
                // 1. Backend Call
                try await FleetManagerService.shared.retireVehicle(byId: id)
                
                // 2. Local Update
                if let index = vehicles.firstIndex(where: { $0.id == id }) {
                    let oldDriverId = vehicles[index].assignedDriverId
                    let registration = vehicles[index].registrationNumber
                    
                    // Update vehicle status and unassign driver
                    vehicles[index].status = .retired
                    vehicles[index].assignedDriverId = nil
                    vehicles[index].assignedDriverName = nil
                    
                    // Update old driver status to available
                    if let dId = oldDriverId, let dIndex = drivers.firstIndex(where: { $0.id == dId }) {
                        drivers[dIndex].status = .available
                    }
                    
                    logActivity(title: "Vehicle Retired", description: "Vehicle \(registration) has been retired from active service.", icon: "archivebox.fill", color: "gray")
                }
                isLoading = false
            } catch {
                self.errorMessage = "Failed to retire vehicle: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ [FleetViewModel] Retire failed: \(error)")
            }
        }
    }
    
    static let maintenanceOptions = [
        "Engine", "Oil", "Oil Change", "Tires", "Tire Replacement",
        "Brakes", "Brake Inspection", "Battery", "Transmission",
        "Suspension", "Electrical", "Cooling System", "Other"
    ]
    
    // MARK: - Computed Helpers
    
    var unassignedDrivers: [FMDriver] {
        let assignedIds = Set(vehicles.compactMap { $0.assignedDriverId })
        return drivers.filter { driver in
            // Must not be in the assigned IDs set AND must be marked as Available
            !assignedIds.contains(driver.id) && (driver.status == .available || driver.status == nil)
        }
    }
    
    func logActivity(title: String, description: String, icon: String, color: String) {
        let activity = FMActivity(id: UUID(), title: title, description: description, timestamp: Date(), icon: icon, color: color)
        activities.insert(activity, at: 0)
    }
    
    func isVehicleRegistered(_ registrationNumber: String) -> Bool {
        vehicles.contains { $0.registrationNumber.lowercased() == registrationNumber.lowercased() }
    }
    
    // MARK: - Helpers
    
    private func getDriverName(for id: UUID?) -> String? {
        guard let id = id else { return nil }
        return drivers.first(where: { $0.id == id })?.fullName
    }
    
    private func loadMockData() {
        // Initial mock data if needed
    }
}
