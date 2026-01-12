//
//  MaintenanceSummary.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
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
