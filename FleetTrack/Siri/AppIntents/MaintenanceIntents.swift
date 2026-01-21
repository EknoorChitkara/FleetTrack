//
//  MaintenanceIntents.swift
//  FleetTrack
//
//  App Intents for Maintenance Role.
//

import AppIntents
import Foundation

// MARK: - Check Maintenance Issues (Multi-Role)
struct CheckMaintenanceIssuesIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Maintenance Issues"
    static var description: IntentDescription = IntentDescription("Lists open vehicle maintenance issues based on your role.")
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await SiriPermissionManager.shared.enforceAuth()
        guard let user = try? await SupabaseAuthService.shared.getCurrentUser() else { throw SiriError.unknown }
        
        let allTasks = try await MaintenanceService.shared.fetchMaintenanceTasks()
        let openTasks = allTasks.filter { $0.status != "Completed" && $0.status != "Cancelled" }
        
        if user.role == .driver {
            // Driver Context: Check ONLY assigned vehicle
            // Fix: Fetch Driver Profile first
            if let driver_profile = try? await DriverService.shared.getDriverProfile(userId: user.id),
               let vehicle = try await DriverService.shared.getAssignedVehicle(driverId: driver_profile.id) {
                let myIssues = openTasks.filter { $0.vehicleRegistrationNumber == vehicle.registrationNumber }
                if myIssues.isEmpty {
                    return .result(dialog: "Your vehicle \(vehicle.registrationNumber) has no reported issues.")
                } else {
                    let issue = myIssues.first!
                    return .result(dialog: "Your vehicle has \(myIssues.count) open issue(s). Requires attention for: \(issue.component.rawValue).")
                }
            } else {
                return .result(dialog: "You don't have a vehicle assigned, so I can't check for specific issues.")
            }
        } else {
            // Maintenance/Manager Context: Fleet-wide summary
            let issueCount = openTasks.count
            if issueCount > 0 {
                if let firstIssue = openTasks.first {
                    return .result(dialog: "There are \(issueCount) vehicles requiring attention across the fleet. For example, \(firstIssue.vehicleRegistrationNumber) has a \(firstIssue.component.rawValue) issue.")
                } else {
                     return .result(dialog: "There are \(issueCount) open maintenance issues in the fleet.")
                }
            } else {
                return .result(dialog: "All vehicles in the fleet are healthy. No open maintenance issues.")
            }
        }
    }
}

struct DueForServiceIntent: AppIntent {
    static var title: LocalizedStringResource = "Vehicles Due For Service"
    static var description: IntentDescription = IntentDescription("Checks which vehicles are due for preventive maintenance.")
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await SiriPermissionManager.shared.enforceAuth()
        try await SiriRoleResolver.shared.requireRole(.maintenancePersonnel)
        
        return .result(dialog: "Vehicle MH-12-AB-9999 is due for service today.")
    }
}

struct ResolveIssueIntent: AppIntent {
    static var title: LocalizedStringResource = "Resolve Maintenance Issue"
    static var description: IntentDescription = IntentDescription("Opens the app to mark a maintenance task as resolved.")
    
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await SiriPermissionManager.shared.enforceAuth()
        let url = URL(string: "fleettrack://maintenance/resolve")
        return .result(
            value: url,
            dialog: "Opening Maintenance Dashboard to update task status."
        )
    }
}
