//
//  FleetTrackShortcuts.swift
//  FleetTrack
//
//  Created for Siri Accessibility
//

import AppIntents

struct FleetTrackShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTripIntent(),
            phrases: [
                "Start my trip in \(.applicationName)",
                "Start next trip in \(.applicationName)",
                "Start trip in \(.applicationName)"
            ],
            shortTitle: "Start Trip",
            systemImageName: "play.fill"
        )
        
        AppShortcut(
            intent: GetFleetSummaryIntent(),
            phrases: [
                "How is the fleet doing in \(.applicationName)",
                "Get fleet status in \(.applicationName)",
                "Get fleet summary in \(.applicationName)"
            ],
            shortTitle: "Fleet Summary",
            systemImageName: "chart.bar.fill"
        )
        
        AppShortcut(
            intent: GetNextTaskIntent(),
            phrases: [
                "What is my next job in \(.applicationName)",
                "What is my next task in \(.applicationName)",
                "Get next maintenance task in \(.applicationName)"
            ],
            shortTitle: "Next Job",
            systemImageName: "wrench.and.screwdriver.fill"
        )
        
        AppShortcut(
            intent: ReportIssueIntent(),
            phrases: [
                "Report an issue in \(.applicationName)",
                "Report a problem in \(.applicationName)",
                "Vehicle breakdown in \(.applicationName)",
                "My vehicle is having an issue in \(.applicationName)"
            ],
            shortTitle: "Report Issue",
            systemImageName: "exclamationmark.triangle.fill"
        )
        
        AppShortcut(
            intent: AssignTripIntent(),
            phrases: [
                "Assign a vehicle in \(.applicationName)",
                "Assign trip in \(.applicationName)",
                "Assign driver in \(.applicationName)"
            ],
            shortTitle: "Assign Trip",
            systemImageName: "person.badge.plus.fill"
        )
    }
}
