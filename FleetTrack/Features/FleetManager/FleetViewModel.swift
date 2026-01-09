import Foundation
import SwiftUI
import Combine

class FleetViewModel: ObservableObject {
    @Published var vehicles: [FMVehicle] = []
    @Published var drivers: [FMDriver] = []
    @Published var trips: [FMTrip] = []
    @Published var activities: [FMActivity] = []
    
    // Singleton for easy access across views
    static let shared = FleetViewModel()
    
    private init() {
        loadMockData()
    }
    
    // MARK: - Actions
    
    func addVehicle(_ data: VehicleCreationData) {
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
            assignedDriverName: getDriverName(for: data.assignedDriverId)
        )
        vehicles.append(newVehicle)
        logActivity(title: "New Vehicle Added", description: "Vehicle \(data.registrationNumber) was added to fleet.", icon: "car.fill", color: "blue")
    }
    
    func addDriver(_ data: DriverCreationData) {
        let newDriver = FMDriver(
            id: UUID(),
            fullName: data.fullName,
            licenseNumber: data.licenseNumber,
            phoneNumber: data.phoneNumber,
            email: data.email,
            address: data.address,
            status: data.status
        )
        drivers.append(newDriver)
        logActivity(title: "New Driver Added", description: "Driver \(data.fullName) was registered.", icon: "person.badge.plus.fill", color: "green")
    }
    
    func addTrip(_ data: TripCreationData) {
        let vehicleName = vehicles.first(where: { $0.id == data.vehicleId })?.registrationNumber ?? "Unknown"
        let newTrip = FMTrip(
            id: UUID(),
            vehicleId: data.vehicleId ?? UUID(),
            vehicleName: vehicleName,
            startLocation: data.startLocation,
            destination: data.destination,
            distance: data.distance,
            startDate: data.startDate,
            startTime: data.startTime
        )
        trips.append(newTrip)
        logActivity(title: "Trip Planned", description: "New trip from \(data.startLocation) to \(data.destination) planned.", icon: "map.fill", color: "purple")
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
    
    private func loadMockData() {
        // Initial mock data if needed
    }
}
