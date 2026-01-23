//
//  AssignTripIntent.swift
//  FleetTrack
//
//  Created for Siri Accessibility
//

import AppIntents
import Foundation
import Supabase

struct AssignTripIntent: AppIntent {
    static var title: LocalizedStringResource = "Assign Trip"
    static var description = IntentDescription("Assigns a vehicle to a driver.")

    @Parameter(title: "Vehicle Registration", description: "The registration number of the vehicle (e.g., MH-01-AB-1234)")
    var registrationNumber: String

    @Parameter(title: "Driver Name", description: "The full name of the driver to assign")
    var driverName: String

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let service = FleetManagerService.shared
        
        do {
            let vehicles = try await service.fetchVehicles()
            let drivers = try await service.fetchDrivers()
            
            guard let vehicle = vehicles.first(where: { $0.registrationNumber.lowercased() == registrationNumber.lowercased() }) else {
                return .result(value: "I couldn't find a vehicle with registration \(registrationNumber).")
            }
            
            guard let driver = drivers.first(where: { 
                $0.displayName.lowercased().contains(driverName.lowercased()) || 
                $0.fullName?.lowercased().contains(driverName.lowercased()) == true 
            }) else {
                return .result(value: "I couldn't find a driver named \(driverName).")
            }
            
            // Perform Reassignment (awaiting to ensure it completes for Siri)
            try await service.reassignDriver(vehicleId: vehicle.id, driverId: driver.id)
            
            // Sync with UI if app is running
            await MainActor.run {
                FleetViewModel.shared.reassignDriver(vehicleId: vehicle.id, driverId: driver.id)
            }
            
            HapticManager.shared.triggerSuccess()
            
            return .result(value: "Vehicle \(vehicle.registrationNumber) has been assigned to \(driver.displayName).")
        } catch {
            HapticManager.shared.triggerError()
            return .result(value: "Error assigning trip: \(error.localizedDescription)")
        }
    }
}
