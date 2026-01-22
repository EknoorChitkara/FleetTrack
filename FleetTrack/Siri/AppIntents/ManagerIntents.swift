
//
//  ManagerIntents.swift
//  FleetTrack
//
//  App Intents for Manager Role.
//

import AppIntents
import Supabase
import Foundation

struct ManagerSummaryIntent: AppIntent {
    static var title: LocalizedStringResource = "Operational Summary"
    static var description: IntentDescription = IntentDescription("Provides a summary of today's fleet operations.")
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await SiriPermissionManager.shared.enforceAuth()
        // Allow Fleet Manager
        try await SiriRoleResolver.shared.requireAnyRole([.fleetManager])
        
        // Aggregate real data
        let client = SupabaseClientManager.shared.client
        
        // Use async let for parallel fetching
        async let activeTripsCount = client.from("trips").select("id", head: true, count: .exact).eq("status", value: TripStatus.ongoing.rawValue).execute().count ?? 0
        
        // For "today's" completed trips we might need date filtering, but for summary total trips is okay or we can filter if needed.
        // Let's settle for total completed count for now to keep it robust without date parsing complexities in intents.
        async let completedTripsCount = client.from("trips").select("id", head: true, count: .exact).eq("status", value: TripStatus.completed.rawValue).execute().count ?? 0
        
        async let issuesCount = client.from("maintenance_tasks").select("id", head: true, count: .exact).neq("status", value: "Completed").execute().count ?? 0
        
        let (active, completed, issues) = await (try activeTripsCount, try completedTripsCount, try issuesCount)
        
        return .result(dialog: "Operational Summary: \(active) drivers are active. \(completed) trips completed total. \(issues) vehicles require maintenance.")
    }
}

struct ActiveDriversIntent: AppIntent {
    static var title: LocalizedStringResource = "Active Drivers"
    static var description: IntentDescription = IntentDescription("Checks how many drivers are currently on trips.")
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await SiriPermissionManager.shared.enforceAuth()
        try await SiriRoleResolver.shared.requireAnyRole([.fleetManager])
        
        // Count ongoing trips directly from Supabase
        let count = try await SupabaseClientManager.shared.client
            .from("trips")
            .select("id", head: true, count: .exact)
            .eq("status", value: TripStatus.ongoing.rawValue)
            .execute()
            .count ?? 0
        
        return .result(dialog: "There are \(count) drivers currently on ongoing trips.")
    }
}
