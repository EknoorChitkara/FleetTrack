//
//  MaintenanceTask.swift
//  FleetTrack
//
//  Created for Maintenance Module
//  Updated to match database schema
//

import Foundation

// MARK: - Part Usage (for MaintenanceTask)
// Note: This is stored as JSONB in the maintenance_tasks table

struct PartUsage: Codable, Hashable {
    var partId: UUID?
    var partName: String
    var quantity: Int
    var unitPrice: Double
    
    var totalCost: Double {
        Double(quantity) * unitPrice
    }
    
    enum CodingKeys: String, CodingKey {
        case partId = "part_id"
        case partName = "part_name"
        case quantity
        case unitPrice = "unit_price"
    }
    
    init(
        partId: UUID? = nil,
        partName: String,
        quantity: Int,
        unitPrice: Double
    ) {
        self.partId = partId
        self.partName = partName
        self.quantity = quantity
        self.unitPrice = unitPrice
    }
}

// MARK: - Maintenance Task (Matches DB `maintenance_tasks` table)

struct MaintenanceTask: Identifiable, Codable, Hashable {
    let id: UUID
    var vehicleRegistrationNumber: String
    var priority: MaintenancePriority
    var component: MaintenanceComponent
    var status: String
    var dueDate: Date
    var completedDate: Date?
    var partsUsed: [PartUsage]
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vehicleRegistrationNumber = "vehicle_registration_number"
        case priority
        case component
        case status
        case dueDate = "due_date"
        case completedDate = "completed_date"
        case partsUsed = "parts_used"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        vehicleRegistrationNumber: String,
        priority: MaintenancePriority,
        component: MaintenanceComponent,
        status: String = "Pending",
        dueDate: Date,
        completedDate: Date? = nil,
        partsUsed: [PartUsage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vehicleRegistrationNumber = vehicleRegistrationNumber
        self.priority = priority
        self.component = component
        self.status = status
        self.dueDate = dueDate
        self.completedDate = completedDate
        self.partsUsed = partsUsed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var totalPartsCost: Double {
        partsUsed.reduce(0) { $0 + $1.totalCost }
    }
    
    var isPending: Bool {
        status == "Pending"
    }
    
    var isCompleted: Bool {
        status == "Completed"
    }
    
    var isOverdue: Bool {
        !isCompleted && dueDate < Date()
    }
}

// MARK: - Mock Data
extension MaintenanceTask {
    static let mockTask1 = MaintenanceTask(
        vehicleRegistrationNumber: "MH-01-AB-1234",
        priority: .high,
        component: .brakes,
        status: "Pending",
        dueDate: Date(),
        partsUsed: [
            PartUsage(partName: "Brake Pads", quantity: 2, unitPrice: 1500.0)
        ]
    )
    
    static let mockTask2 = MaintenanceTask(
        vehicleRegistrationNumber: "DL-01-XY-5678",
        priority: .medium,
        component: .engine,
        status: "Completed",
        dueDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        completedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
        partsUsed: [
            PartUsage(partName: "Oil Filter", quantity: 1, unitPrice: 450.0),
            PartUsage(partName: "Engine Oil", quantity: 5, unitPrice: 350.0)
        ]
    )
    
    static let mockTasks: [MaintenanceTask] = [mockTask1, mockTask2]
}
