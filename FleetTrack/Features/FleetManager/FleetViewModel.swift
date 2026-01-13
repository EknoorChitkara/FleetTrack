import Foundation
import SwiftUI
import Combine

class FleetViewModel: ObservableObject {
    @Published var vehicles: [FMVehicle] = []
    @Published var drivers: [FMDriver] = []
    @Published var trips: [FMTrip] = []
    @Published var activities: [FMActivity] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    private var hasLoadedOnce = false
    
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
            async let fetchedTrips = FleetManagerService.shared.fetchTrips()
            
            // Wait for all fetches and merge Results
            self.mergeVehicles(try await fetchedVehicles)
            self.mergeDrivers(try await fetchedDrivers)
            self.trips = try await fetchedTrips
            
            self.hasLoadedOnce = true
            self.isLoading = false
            print("✅ Fleet Data Merged: \(vehicles.count) vehicles, \(drivers.count) drivers")
        } catch {
            self.errorMessage = "Failed to load fleet data: \(error.localizedDescription)"
            self.isLoading = false
            print("❌ Error loading fleet data: \(error)")
        }
    }
    
    // MARK: - Actions
    
    func addVehicle(_ data: VehicleCreationData) {
        // Construct a local model for immediate UI reflection (True Optimistic Update)
        let newVehicle = FMVehicle(
            id: UUID(),
            registrationNumber: data.registrationNumber.uppercased(),
            vehicleType: data.vehicleType,
            manufacturer: data.manufacturer,
            model: data.model,
            fuelType: data.fuelType,
            capacity: data.capacity,
            registrationDate: data.registrationDate,
            status: data.status,
            assignedDriverId: data.assignedDriverId,
            assignedDriverName: getDriverName(for: data.assignedDriverId)
        )
        
        // Add locally first
        self.vehicles.append(newVehicle)
        self.logActivity(title: "New Vehicle Added", description: "Vehicle \(data.registrationNumber) was added to fleet.", icon: "car.fill", color: "blue")
        
        isLoading = true
        Task { @MainActor in
            do {
                try await FleetManagerService.shared.addVehicle(data, id: newVehicle.id)
                self.isLoading = false
                print("✅ Vehicle added successfully to backend")
            } catch {
                // Revert local change on failure
                self.vehicles.removeAll(where: { $0.registrationNumber == newVehicle.registrationNumber })
                self.errorMessage = "Failed to add vehicle: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ Failed to add vehicle: \(error)")
            }
        }
    }
    
    func addDriver(_ data: DriverCreationData) {
        // Construct a local model for immediate UI reflection (True Optimistic Update)
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
        
        // Add locally first
        self.drivers.append(newDriver)
        self.logActivity(title: "New Driver Invited", description: "Invitation sent to \(data.email).", icon: "person.fill", color: "green")
        
        isLoading = true
        Task { @MainActor in
            do {
                try await FleetManagerService.shared.addDriver(data, id: newDriver.id)
                self.isLoading = false
                print("✅ Driver added successfully to backend")
            } catch {
                // Revert local change on failure
                self.drivers.removeAll(where: { $0.email == newDriver.email })
                self.errorMessage = "Failed to add driver: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ Failed to add driver: \(error)")
            }
        }
    }
    
    func addTrip(_ data: TripCreationData) {
        isLoading = true
        Task { @MainActor in
            do {
                try await FleetManagerService.shared.addTrip(data)
                
                // Optimistic UI Update
                let newTrip = FMTrip(
                    id: UUID(),
                    vehicleId: data.vehicleId ?? UUID(),
                    vehicleName: "Vehicle", // Placeholder
                    startLocation: data.startLocation,
                    destination: data.destination,
                    distance: data.distance,
                    startDate: data.startDate,
                    startTime: data.startTime,
                    status: "Scheduled"
                )
                self.trips.append(newTrip)
                self.logActivity(title: "New Trip Scheduled", description: "Trip to \(data.destination) created.", icon: "map.fill", color: "orange")
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to add trip: \(error.localizedDescription)"
                self.isLoading = false
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
    
    func logActivity(title: String, description: String, icon: String, color: String) {
        let activity = FMActivity(id: UUID(), title: title, description: description, timestamp: Date(), icon: icon, color: color)
        activities.insert(activity, at: 0)
    }
    
    // MARK: - Helpers
    
    private func getDriverName(for id: UUID?) -> String? {
        guard let id = id else { return nil }
        return drivers.first(where: { $0.id == id })?.fullName
    }
    
    // MARK: - Merging Logic
    
    private func mergeVehicles(_ fetched: [FMVehicle]) {
        var current = self.vehicles
        
        for vehicle in fetched {
            if let index = current.firstIndex(where: { $0.id == vehicle.id }) {
                // Update existing
                current[index] = vehicle
            } else if !current.contains(where: { $0.registrationNumber == vehicle.registrationNumber }) {
                // Append new if not already present (checking reg no to avoid duplicates if ID changed)
                current.append(vehicle)
            }
        }
        
        self.vehicles = current
    }
    
    private func mergeDrivers(_ fetched: [FMDriver]) {
        var current = self.drivers
        
        for driver in fetched {
            if let index = current.firstIndex(where: { $0.id == driver.id }) {
                // Update existing
                current[index] = driver
            } else if !current.contains(where: { $0.email == driver.email }) {
                // Append new if not already present
                current.append(driver)
            }
        }
        
        self.drivers = current
    }
    
    private func loadMockData() {
        // Initial mock data if needed
    }
}
