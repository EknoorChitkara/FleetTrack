//
//  MaintenanceSummary.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import Foundation

public struct MaintenanceSummary: Codable, Hashable {
    public var completedTasksThisMonth: Int
    public var averageCompletionTimeHours: Double

    public init(
        completedTasksThisMonth: Int = 0,
        averageCompletionTimeHours: Double = 0.0
    ) {
        self.completedTasksThisMonth = completedTasksThisMonth
        self.averageCompletionTimeHours = averageCompletionTimeHours
    }
}
