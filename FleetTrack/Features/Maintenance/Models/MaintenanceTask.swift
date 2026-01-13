//
//  MaintenanceTask.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//


import Foundation

// MARK: - Maintenance Task

struct MaintenanceTask: Identifiable, Codable, Hashable {
    let id: UUID
    var vehicleRegistrationNumber: String
    var priority: MaintenancePriority
    var component: MaintenanceComponent
    var status: String // Using String for flexibility as requested, or could be mapped to Core.MaintenanceStatus
    var dueDate: Date
    var completedDate: Date?
    var partsUsed: [PartUsage]
    
    init(
        id: UUID = UUID(),
        vehicleRegistrationNumber: String,
        priority: MaintenancePriority,
        component: MaintenanceComponent,
        status: String = "Pending",
        dueDate: Date,
        completedDate: Date? = nil,
        partsUsed: [PartUsage] = []
    ) {
        self.id = id
        self.vehicleRegistrationNumber = vehicleRegistrationNumber
        self.priority = priority
        self.component = component
        self.status = status
        self.dueDate = dueDate
        self.completedDate = completedDate
        self.partsUsed = partsUsed
    }
    
    // MARK: - Computed Properties
    
    var totalPartsCost: Double {
        partsUsed.reduce(0) { $0 + $1.totalCost }
    }
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case vehicleRegistrationNumber = "vehicle_registration_number"
        case priority
        case component
        case status
        case dueDate = "due_date"
        case completedDate = "completed_date"
        case partsUsed = "parts_used"
    }
}
