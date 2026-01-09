//
//  MaintenanceSummary.swift
//  FleetTrack
//
//  Created by FleetTrack Team on 2026-01-09.
//

import Foundation

struct MaintenanceSummary: Codable, Hashable {
    var completedTasksThisMonth: Int
    var averageCompletionTimeHours: Double
    
    init(
        completedTasksThisMonth: Int = 0,
        averageCompletionTimeHours: Double = 0.0
    ) {
        self.completedTasksThisMonth = completedTasksThisMonth
        self.averageCompletionTimeHours = averageCompletionTimeHours
    }
}
