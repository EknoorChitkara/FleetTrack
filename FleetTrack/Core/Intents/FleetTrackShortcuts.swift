//
//  FleetTrackShortcuts.swift
//  FleetTrack
//
//  Created for Siri Accessibility
//

import AppIntents

struct FleetTrackShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // MARK: - Auth & Session
        AppShortcut(
            intent: CheckLoginStatusIntent(),
            phrases: [
                "Verify my session in \(.applicationName)",
                "Debug login status in \(.applicationName)",
                "Am I authenticated in \(.applicationName)?"
            ],
            shortTitle: "Verify Session",
            systemImageName: "person.badge.shield.checkmark.fill"
        )

        // MARK: - Vehicle & Navigation (Driver)
        AppShortcut(
            intent: CheckAssignedVehicleIntent(),
            phrases: [
                "Which vehicle is assigned to me in \(.applicationName)?",
                "Check my vehicle in \(.applicationName)",
                "What am I driving in \(.applicationName)?",
                "Show my truck in \(.applicationName)"
            ],
            shortTitle: "Check Vehicle",
            systemImageName: "car.fill"
        )
        
        AppShortcut(
            intent: VoiceStartTripIntent(),
            phrases: [
                "Start my trip in \(.applicationName)",
                "Start trip in \(.applicationName)",
                "Begin delivery in \(.applicationName)",
                "Start driving in \(.applicationName)",
                "Go to destination in \(.applicationName)"
            ],
            shortTitle: "Start Trip",
            systemImageName: "play.circle.fill"
        )
        
        AppShortcut(
            intent: EndTripIntent(),
            phrases: [
                "End my trip in \(.applicationName)",
                "Stop my trip in \(.applicationName)"
            ],
            shortTitle: "End Trip",
            systemImageName: "stop.circle.fill"
        )
        
        AppShortcut(
            intent: CheckBestRouteIntent(),
            phrases: [
                "Which route saves fuel in \(.applicationName)?",
                "Which route is fastest in \(.applicationName)?",
                "Recommend the best route in \(.applicationName)",
                "Estimate fuel for this trip in \(.applicationName)"
            ],
            shortTitle: "Best Route",
            systemImageName: "leaf.fill"
        )
        
        // MARK: - Issues & Maintenance (Driver + Maintenance Role)
        AppShortcut(
            intent: CheckMaintenanceIssuesIntent(),
            phrases: [
                "Are there any vehicle issues in \(.applicationName)?",
                "Show maintenance issues in \(.applicationName)",
                "List open vehicle issues in \(.applicationName)",
                "Any maintenance alerts in \(.applicationName)?"
            ],
            shortTitle: "Check Issues",
            systemImageName: "wrench.and.screwdriver.fill"
        )
        
        AppShortcut(
            intent: ReportIssueIntent(),
            phrases: [
                "Report a vehicle problem in \(.applicationName)",
                "Report an issue in \(.applicationName)"
            ],
            shortTitle: "Report Issue",
            systemImageName: "exclamationmark.triangle.fill"
        )
        
        AppShortcut(
            intent: DueForServiceIntent(),
            phrases: [
                "Any vehicles due for service in \(.applicationName)?",
                "Check vehicle health in \(.applicationName)",
                "Show upcoming maintenance in \(.applicationName)"
            ],
            shortTitle: "Due For Service",
            systemImageName: "calendar.badge.exclamationmark"
        )
        
        AppShortcut(
            intent: ResolveIssueIntent(),
            phrases: [
                "Mark issue as resolved in \(.applicationName)",
                "Update maintenance status in \(.applicationName)"
            ],
            shortTitle: "Resolve Issue",
            systemImageName: "checkmark.seal.fill"
        )
        
        // MARK: - Manager Stats
        AppShortcut(
            intent: ManagerSummaryIntent(),
            phrases: [
                "Give today's operational summary in \(.applicationName)",
                "How many drivers are active in \(.applicationName)?",
                "Check ongoing trips in \(.applicationName)",
                "Show active trips in \(.applicationName)",
                "Any critical alerts in \(.applicationName)?"
            ],
            shortTitle: "Daily Summary",
            systemImageName: "chart.bar.fill"
        )
    }

}
