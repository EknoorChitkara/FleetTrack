//
//  GetNextTaskIntent.swift
//  FleetTrack
//
//  Created for Siri Accessibility
//

import AppIntents
import Foundation
import Supabase

struct GetNextTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Next Maintenance Task"
    static var description = IntentDescription("Tells the maintenance staff their next high-priority task.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // 1. Check Auth
        guard let _ = try? await SupabaseClientManager.shared.client.auth.session else {
            return .result(value: "Please log in to FleetTrack.")
        }
        
        let service = MaintenanceService.shared
        
        do {
            let tasks = try await service.fetchMaintenanceTasks()
            
            // Filter for pending tasks, sorted by priority (assuming High > Medium > Low)
            let pendingTasks = tasks.filter { $0.status.lowercased() == "pending" }
                .sorted { t1, t2 in
                    let p1 = t1.priority.rawValue
                    let p2 = t2.priority.rawValue
                    return p1 < p2 // Simplified priority sorting
                }
            
            if let nextTask = pendingTasks.first {
                HapticManager.shared.triggerSuccess()
                let summary = "Your next task is a \(nextTask.priority.rawValue) priority \(nextTask.component.rawValue) for vehicle \(nextTask.vehicleRegistrationNumber). It's due on \(nextTask.dueDate.formatted(date: .abbreviated, time: .omitted))."
                return .result(value: summary)
            } else {
                return .result(value: "You have no pending maintenance tasks. Great job!")
            }
        } catch {
            print("❌ Siri GetNextTaskIntent Failed: \(error)")
            HapticManager.shared.triggerError()
            return .result(value: "I couldn't fetch your tasks right now.")
        }
    }
}
