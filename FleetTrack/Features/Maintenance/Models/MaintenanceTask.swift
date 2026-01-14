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
    var status: String // Keep as String for backward compatibility
    var dueDate: Date
    var completedDate: Date?
    var partsUsed: [PartUsage]
    var createdAt: Date
    var updatedAt: Date
    
    // NEW FIELDS for enhanced task management
    var taskType: TaskType
    var description: String?
    var estimatedServiceHours: Double?
    var assignedDriverId: UUID?
    var assignedVehicleId: UUID?
    var isLocked: Bool
    var laborHours: Double?
    var repairDescription: String?
    var startedAt: Date?
    var pausedAt: Date?
    var failedReason: String?
    
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
        case taskType = "task_type"
        case description
        case estimatedServiceHours = "estimated_service_hours"
        case assignedDriverId = "assigned_driver_id"
        case assignedVehicleId = "assigned_vehicle_id"
        case isLocked = "is_locked"
        case laborHours = "labor_hours"
        case repairDescription = "repair_description"
        case startedAt = "started_at"
        case pausedAt = "paused_at"
        case failedReason = "failed_reason"
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
        updatedAt: Date = Date(),
        taskType: TaskType = .scheduled,
        description: String? = nil,
        estimatedServiceHours: Double? = nil,
        assignedDriverId: UUID? = nil,
        assignedVehicleId: UUID? = nil,
        isLocked: Bool = false,
        laborHours: Double? = nil,
        repairDescription: String? = nil,
        startedAt: Date? = nil,
        pausedAt: Date? = nil,
        failedReason: String? = nil
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
        self.taskType = taskType
        self.description = description
        self.estimatedServiceHours = estimatedServiceHours
        self.assignedDriverId = assignedDriverId
        self.assignedVehicleId = assignedVehicleId
        self.isLocked = isLocked
        self.laborHours = laborHours
        self.repairDescription = repairDescription
        self.startedAt = startedAt
        self.pausedAt = pausedAt
        self.failedReason = failedReason
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
    
    var taskStatusEnum: TaskStatus {
        TaskStatus(rawValue: status) ?? .pending
    }
    
    var canBeEdited: Bool {
        !isLocked && !isCompleted
    }
    
    var canBeStarted: Bool {
        status == "Pending"
    }
    
    var canBePaused: Bool {
        status == "In Progress"
    }
    
    var canBeResumed: Bool {
        status == "Paused"
    }
    
    var canBeCompleted: Bool {
        status == "In Progress" || status == "Paused"
    }
    
    var totalCost: Double {
        totalPartsCost + (laborHours ?? 0) * 500 // Assuming ₹500/hour labor rate
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
        ],
        taskType: .emergency,
        description: "Brake pads showing excessive wear. Immediate replacement required for safety."
    )
    
    static let mockTask2 = MaintenanceTask(
        vehicleRegistrationNumber: "DL-01-XY-5678",
        priority: .medium,
        component: .engine,
        status: "In Progress",
        dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
        partsUsed: [
            PartUsage(partName: "Oil Filter", quantity: 1, unitPrice: 450.0),
            PartUsage(partName: "Engine Oil", quantity: 5, unitPrice: 350.0)
        ],
        taskType: .scheduled,
        description: "Regular engine oil change and filter replacement",
        laborHours: 2.5,
        repairDescription: "Drained old oil, replaced filter, added new synthetic oil",
        startedAt: Calendar.current.date(byAdding: .hour, value: -1, to: Date())
    )
    
    static let mockTask3 = MaintenanceTask(
        vehicleRegistrationNumber: "KA-03-CD-9012",
        priority: .low,
        component: .tires,
        status: "Completed",
        dueDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
        completedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
        partsUsed: [
            PartUsage(partName: "Front Tire", quantity: 2, unitPrice: 3500.0)
        ],
        taskType: .scheduled,
        description: "Front tire replacement due to wear",
        isLocked: true,
        laborHours: 1.5,
        repairDescription: "Replaced both front tires, balanced wheels, checked alignment"
    )
    
    static let mockTask4 = MaintenanceTask(
        vehicleRegistrationNumber: "TN-05-EF-3456",
        priority: .high,
        component: .transmission,
        status: "Paused",
        dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
        partsUsed: [],
        taskType: .emergency,
        description: "Transmission fluid leak detected",
        laborHours: 3.0,
        repairDescription: "Identified leak source, waiting for replacement gasket",
        startedAt: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!,
        pausedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())
    )
    
    static let mockTask5 = MaintenanceTask(
        vehicleRegistrationNumber: "MH-02-GH-7890",
        priority: .medium,
        component: .suspension,
        status: "Pending",
        dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
        partsUsed: [],
        taskType: .scheduled,
        description: "Routine suspension inspection and maintenance"
    )
    
    static let mockTask6 = MaintenanceTask(
        vehicleRegistrationNumber: "DL-04-IJ-2345",
        priority: .high,
        component: .electrical,
        status: "Failed",
        dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
        completedDate: Date(),
        partsUsed: [
            PartUsage(partName: "Battery", quantity: 1, unitPrice: 5500.0)
        ],
        taskType: .emergency,
        description: "Battery replacement - vehicle won't start",
        isLocked: true,
        laborHours: 1.0,
        repairDescription: "Attempted battery replacement but alternator also faulty",
        failedReason: "Alternator needs replacement before battery can be installed"
    )
    
    static let mockTask7 = MaintenanceTask(
        vehicleRegistrationNumber: "KA-01-KL-6789",
        priority: .low,
        component: .coolingSystem,
        status: "Pending",
        dueDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!,
        partsUsed: [],
        taskType: .scheduled,
        description: "Cooling system check and refrigerant refill"
    )
    
    static let mockTask8 = MaintenanceTask(
        vehicleRegistrationNumber: "TN-02-MN-4567",
        priority: .medium,
        component: .brakes,
        status: "In Progress",
        dueDate: Date(),
        partsUsed: [
            PartUsage(partName: "Brake Fluid", quantity: 1, unitPrice: 800.0)
        ],
        taskType: .scheduled,
        description: "Brake fluid flush and replacement",
        laborHours: 1.5,
        repairDescription: "Flushing old brake fluid, replacing with DOT 4",
        startedAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date())
    )
    
    static let mockTask9 = MaintenanceTask(
        vehicleRegistrationNumber: "MH-03-OP-8901",
        priority: .high,
        component: .engine,
        status: "Pending",
        dueDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        partsUsed: [],
        taskType: .emergency,
        description: "Engine overheating - coolant leak suspected"
    )
    
    static let mockTask10 = MaintenanceTask(
        vehicleRegistrationNumber: "DL-05-QR-1234",
        priority: .low,
        component: .electrical,
        status: "Completed",
        dueDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
        completedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        partsUsed: [
            PartUsage(partName: "Headlight Bulb", quantity: 2, unitPrice: 800.0),
            PartUsage(partName: "Tail Light", quantity: 1, unitPrice: 600.0)
        ],
        taskType: .scheduled,
        description: "Headlight and tail light replacement",
        isLocked: true,
        laborHours: 1.0,
        repairDescription: "Replaced both headlight bulbs and one tail light"
    )
    
    static let mockTasks: [MaintenanceTask] = [
        mockTask1, mockTask2, mockTask3, mockTask4, mockTask5,
        mockTask6, mockTask7, mockTask8, mockTask9, mockTask10
    ]
}
