//
//  StartTripIntent.swift
//  FleetTrack
//
//  Created for Siri Accessibility
//

import AppIntents
import Foundation
import Supabase

struct StartTripIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Next Trip"
    static var description = IntentDescription("Starts your next scheduled trip in FleetTrack.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // 1. Check Auth Session
        guard let currentSession = try? await SupabaseClientManager.shared.client.auth.session else {
            return .result(value: "Please log in to the FleetTrack app first.")
        }
        
        let userId = currentSession.user.id
        
        let driverService = DriverService.shared
        let tripService = TripService.shared
        
        do {
            // 2. Fetch Driver Profile
            let driver = try await driverService.getDriverProfile(userId: userId)
            
            // 3. Find Next Scheduled Trip
            if let nextTrip = try await driverService.getNextScheduledTrip(driverId: driver.id) {
                // 4. Start the trip
                try await tripService.startTrip(tripId: nextTrip.id)
                HapticManager.shared.triggerSuccess()
                
                return .result(value: "Trip to \(nextTrip.endAddress) started successfully. Drive safely!")
            } else {
                return .result(value: "You have no scheduled trips at the moment.")
            }
        } catch {
            print("❌ Siri StartTripIntent Failed: \(error)")
            HapticManager.shared.triggerError()
            return .result(value: "Sorry, I encountered an error while trying to start your trip. Please open the app.")
        }
    }
}
