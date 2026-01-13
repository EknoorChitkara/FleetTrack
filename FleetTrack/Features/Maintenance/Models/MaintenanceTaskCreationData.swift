//
//  MaintenanceTaskCreationData.swift
//  FleetTrack
//
//  Created for Maintenance Module
//

import Foundation

/// Form data model for creating new maintenance tasks
struct MaintenanceTaskCreationData {
    var vehicleRegistrationNumber: String = ""
    var priority: MaintenancePriority = .medium
    var component: MaintenanceComponent = .engine
    var status: String = "Pending"
    var dueDate: Date = Date()
    var partsUsed: [PartUsage] = []
    
    /// Convert to MaintenanceTask for database insertion
    func toMaintenanceTask() -> MaintenanceTask {
        MaintenanceTask(
            vehicleRegistrationNumber: vehicleRegistrationNumber,
            priority: priority,
            component: component,
            status: status,
            dueDate: dueDate,
            partsUsed: partsUsed
        )
    }
}
