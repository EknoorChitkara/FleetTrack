//
//  GetFleetSummaryIntent.swift
//  FleetTrack
//
//  Created for Siri Accessibility
//

import AppIntents
import Foundation
import Supabase

struct GetFleetSummaryIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Fleet Summary"
    static var description = IntentDescription("Provides a spoken summary of the fleet status for Managers.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // 1. Check Auth & Role (Simplified for demo, usually you'd check role in User profile)
        guard let _ = try? await SupabaseClientManager.shared.client.auth.session else {
            return .result(value: "Please log in to FleetTrack.")
        }
        
        let service = FleetManagerService.shared
        
        do {
            async let vehicles = service.fetchVehicles()
            async let drivers = service.fetchDrivers()
            async let trips = service.fetchTrips()
            
            let allVehicles = try await vehicles
            let allDrivers = try await drivers
            let allTrips = try await trips
            
            let inMaintenance = allVehicles.filter { $0.status == .inMaintenance }.count
            let activeTrips = allTrips.filter { $0.status.lowercased() == "ongoing" }.count
            let availableDrivers = allDrivers.filter { $0.status == .available }.count
            
            let summary = """
            Here's your fleet status: 
            You have \(allVehicles.count) vehicles in total, with \(inMaintenance) currently in maintenance. 
            There are \(activeTrips) ongoing trips and \(availableDrivers) drivers available for assignment.
            """
            
            HapticManager.shared.triggerSuccess()
            return .result(value: summary)
        } catch {
            print("❌ Siri GetFleetSummaryIntent Failed: \(error)")
            HapticManager.shared.triggerError()
            return .result(value: "I couldn't fetch the fleet data right now. Please check the dashboard.")
        }
    }
}
