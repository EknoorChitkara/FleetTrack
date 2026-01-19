//
//  ReportIssueIntent.swift
//  FleetTrack
//
//  Created for Siri Accessibility
//

import AppIntents
import Foundation
import Supabase

struct ReportIssueIntent: AppIntent {
    static var title: LocalizedStringResource = "Report an Issue"
    static var description = IntentDescription("Reports a maintenance or vehicle issue.")

    @Parameter(title: "Issue", description: "What is the issue? (e.g., Engine issue, Tire puncture)")
    var issueTitle: String

    @Parameter(title: "Description", description: "Optional details about the issue")
    var descriptionText: String?

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        do {
            // 1. Create Alert record
            let alert = AlertCreate(
                tripId: nil, // Siri context might not have trip ID easily
                title: issueTitle,
                message: descriptionText ?? issueTitle,
                type: "Critical", // Default to Critical for Siri reports
                timestamp: timestamp,
                isRead: false
            )
            
            try await supabase
                .from("alerts")
                .insert(alert)
                .execute()
            
            // 2. Create Maintenance Alert
            let maintenanceAlert = MaintenanceAlertCreate(
                title: "Voice Report: \(issueTitle)",
                message: descriptionText ?? "Reported via Siri",
                type: "Emergency",
                date: timestamp,
                isRead: false
            )
            
            try await supabase
                .from("maintenance_alerts")
                .insert(maintenanceAlert)
                .execute()
            
            HapticManager.shared.triggerSuccess()
            return .result(value: "I've reported the \(issueTitle) to the fleet manager. Stay safe!")
        } catch {
            print("❌ Siri ReportIssueIntent Failed: \(error)")
            HapticManager.shared.triggerError()
            return .result(value: "Sorry, I couldn't submit your report. Please check your connection.")
        }
    }
}
