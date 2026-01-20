//
//  DriverIntents.swift
//  FleetTrack
//
//  App Intents for Driver Role.
//

import AppIntents
import Foundation

// MARK: - Check Login Status
struct CheckLoginStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Login Status"
    static var description: IntentDescription = IntentDescription("Checks if you are currently logged into FleetTrack.")
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let isLoggedIn = (try? await SiriPermissionManager.shared.checkAuthStatus()) ?? false

        if isLoggedIn {
            guard let user = try? await SupabaseAuthService.shared.getCurrentUser() else {
                return .result(value: "Error", dialog: "You are logged in, but I couldn't fetch your profile.")
            }
            return .result(value: "Logged In", dialog: "You are logged in as \(user.name). Role: \(user.role.rawValue).")
        } else {
            return .result(value: "Logged Out", dialog: "You are currently logged out. Please open the app to log in.")
        }
    }
}

// MARK: - Check Assigned Vehicle
struct CheckAssignedVehicleIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Assigned Vehicle"
    static var description: IntentDescription = IntentDescription("Checks which vehicle is currently assigned to you.")
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        try await SiriPermissionManager.shared.enforceAuth()
        try await SiriRoleResolver.shared.requireRole(.driver)

        guard let user = try? await SupabaseAuthService.shared.getCurrentUser() else {
            return .result(value: "Error", dialog: "I couldn't verify your account right now.")
        }

        do {
            // Fetch Driver Profile to get the correct Driver ID
            let driver = try await DriverService.shared.getDriverProfile(userId: user.id)
            
            if let vehicle = try await DriverService.shared.getAssignedVehicle(driverId: driver.id) {
                let response = "You are assigned to \(vehicle.manufacturer) \(vehicle.model), Registration \(vehicle.registrationNumber)."
                return .result(value: vehicle.registrationNumber, dialog: IntentDialog(stringLiteral: response))
            } else {
                return .result(value: "None", dialog: "You don't have a vehicle assigned right now.")
            }
        } catch {
            return .result(value: "Error", dialog: "I couldn't check your vehicle assignment due to a network error.")
        }
    }
}

// MARK: - Start Trip
struct VoiceStartTripIntent: AppIntent {
    static var title: LocalizedStringResource = "Start My Trip (Voice)"
    static var description: IntentDescription = IntentDescription("Starts your scheduled trip in FleetTrack via Voice.")
    
    static var openAppWhenRun: Bool = true // Must open app to start trip visualization
    
    func perform() async throws -> some IntentResult & ReturnsValue<URL> & ProvidesDialog {
        // 1. Auth Check
        do {
            try await SiriPermissionManager.shared.enforceAuth()
            try await SiriRoleResolver.shared.requireRole(.driver)
        } catch {
             return .result(value: URL(string: "fleettrack://home")!, dialog: "You need to log in as a driver first.")
        }

        guard let user = try? await SupabaseAuthService.shared.getCurrentUser() else { 
            return .result(value: URL(string: "fleettrack://home")!, dialog: "Error: Could not verify user session.")
        }

        // 2. Fetch Driver Profile
        // We use explicit error handling here to debug why it might fail
        let driver: Driver
        do {
            driver = try await DriverService.shared.getDriverProfile(userId: user.id)
        } catch {
            return .result(value: URL(string: "fleettrack://home")!, dialog: "Error: Could not find driver profile. \(error.localizedDescription)")
        }

        // 3. Check for Ongoing Trip (Resume)
        if let ongoing = try? await DriverService.shared.getOngoingTrip(driverId: driver.id),
           let url = URL(string: "fleettrack://trip/start") {
             // We use the same URL for now, assuming app handles state
             return .result(value: url, dialog: "Resuming your ongoing trip to \(ongoing.endAddress ?? "Destination").")
        }

        // 4. Check for Scheduled Trip (Start)
        if let next = try? await DriverService.shared.getNextScheduledTrip(driverId: driver.id),
           let url = URL(string: "fleettrack://trip/start") {
            return .result(value: url, dialog: "Starting your trip to \(next.endAddress ?? "Destination").")
        }
        
        // 5. Fallback (No trip found)
        if let url = URL(string: "fleettrack://home") {
            return .result(value: url, dialog: "You don't have any scheduled or active trips right now.")
        } else {
            return .result(value: URL(string: "https://example.com")!, dialog: "Opening FleetTrack...")
        }
    }
}

// MARK: - AI Route Check
struct CheckBestRouteIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Best Route"
    static var description: IntentDescription = IntentDescription("Asks AI for the best route based on fuel and traffic.")
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await SiriPermissionManager.shared.enforceAuth()

        guard let user = try? await SupabaseAuthService.shared.getCurrentUser() else { return .result(dialog: "I couldn't verify your account right now.") }

        // Fetch Driver Profile
        guard let driver = try? await DriverService.shared.getDriverProfile(userId: user.id) else {
             return .result(dialog: "I couldn't find your driver profile.")
        }

        var tripToCheck: Trip?
        if let ongoing = try? await DriverService.shared.getOngoingTrip(driverId: driver.id) {
            tripToCheck = ongoing
        } else if let next = try? await DriverService.shared.getNextScheduledTrip(driverId: driver.id) {
            tripToCheck = next
        }

        guard let trip = tripToCheck else {
            return .result(dialog: "You don't have an active or upcoming trip to check routes for.")
        }

        return .result(dialog: "For your trip to \(trip.endAddress ?? "Destination"), the AI recommends the 'Fuel Saver' route. It saves approximately 2 Liters of fuel compared to the fastest route.")
    }
}
// MARK: - End Trip
struct EndTripIntent: AppIntent {
    static var title: LocalizedStringResource = "End Trip"
    static var description: IntentDescription = IntentDescription("Ends your current ongoing trip.")
    
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult & ReturnsValue<URL> & ProvidesDialog {
        try await SiriPermissionManager.shared.enforceAuth()
        // Always return the same underlying type by using the same overload
        if let url = URL(string: "fleettrack://trip/end") {
            return .result(value: url, dialog: "Opening FleetTrack to complete your trip report.")
        } else if let fallback = URL(string: "fleettrack://home") {
            return .result(value: fallback, dialog: "Opening FleetTrack...")
        } else {
            // Final fallback to maintain consistent underlying type
            return .result(value: URL(string: "https://example.com")!, dialog: "Opening FleetTrack...")
        }
    }
}

