
//
//  SiriCommandRouter.swift
//  FleetTrack
//
//  Routes voice commands to appropriate handlers based on role and context.
//

import Foundation
import AppIntents

class SiriCommandRouter {
    static let shared = SiriCommandRouter()
    
    // This class serves as a central point if we had generic "Do X" intents.
    // However, App Intents are strongly typed.
    // We will use this mainly for shared logic or dispatching complex generic queries.
    
    private init() {}
    
    // Example: Generic "Status Report" that differs by role
    func getStatusReport() async throws -> String {
        guard let role = await SiriRoleResolver.shared.getCurrentRole() else {
            return "Please log in to check your status."
        }
        
        switch role {
        case .driver:
            return await getDriverStatus()
        case .fleetManager:
            return await getManagerStatus()
        case .maintenancePersonnel:
             return await getMaintenanceStatus()
        }
    }
    
    private func getDriverStatus() async -> String {
        // Logic to fetch driver status
        guard let user = try? await SupabaseAuthService.shared.getCurrentUser() else { return "Error fetching user." }
        
        // Use DriverService (Assuming it exists and is accessible)
        // Since we are in the same module, we can access Singletons
        do {
            if let trip = try await DriverService.shared.getOngoingTrip(driverId: user.id) {
                return "You have an active trip to \(trip.endAddress ?? "Destination")."
            } else if let nextTrip = try await DriverService.shared.getNextScheduledTrip(driverId: user.id) {
                return "You have a trip scheduled for \(nextTrip.startTime?.formatted() ?? "soon")."
            } else {
                return "You have no active or upcoming trips."
            }
        } catch {
            return "I couldn't check your trips right now."
        }
    }
    
    private func getManagerStatus() async -> String {
        return "Manager Dashboard: 5 Drivers Active, 2 Alerts." // Placeholder real logic implementation would go here
    }
    
    private func getMaintenanceStatus() async -> String {
         return "Maintenance: 3 Vehicles require attention."
    }
}
