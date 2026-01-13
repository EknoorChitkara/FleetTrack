//
//  MaintenanceRecord.swift
//  FleetTrack
//
//  Professional Fleet Management System
//  Updated to match database schema
//

import Foundation

// MARK: - Enums

enum MaintenanceType: String, Codable, CaseIterable {
    case scheduledService = "Scheduled Service"
    case repair = "Repair"
    case inspection = "Inspection"
    case emergency = "Emergency"
}

enum MaintenanceStatus: String, Codable, CaseIterable {
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

// MARK: - Maintenance Record Model (Matches DB Schema)

struct MaintenanceRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var vehicleId: UUID
    var type: MaintenanceType
    var status: MaintenanceStatus
    
    // Service details
    var title: String
    var description: String?
    var scheduledDate: Date
    var startedDate: Date?
    var completedDate: Date?
    
    // Personnel
    var performedBy: UUID? // Maintenance Personnel ID
    
    // Cost
    var laborCost: Double
    
    // Mileage at service
    var mileageAtService: Double?
    
    // Notes
    var workNotes: String?
    var recommendations: String?
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vehicleId = "vehicle_id"
        case type
        case status
        case title
        case description
        case scheduledDate = "scheduled_date"
        case startedDate = "started_date"
        case completedDate = "completed_date"
        case performedBy = "performed_by"
        case laborCost = "labor_cost"
        case mileageAtService = "mileage_at_service"
        case workNotes = "work_notes"
        case recommendations
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        vehicleId: UUID,
        type: MaintenanceType,
        status: MaintenanceStatus = .scheduled,
        title: String,
        description: String? = nil,
        scheduledDate: Date,
        startedDate: Date? = nil,
        completedDate: Date? = nil,
        performedBy: UUID? = nil,
        laborCost: Double = 0,
        mileageAtService: Double? = nil,
        workNotes: String? = nil,
        recommendations: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vehicleId = vehicleId
        self.type = type
        self.status = status
        self.title = title
        self.description = description
        self.scheduledDate = scheduledDate
        self.startedDate = startedDate
        self.completedDate = completedDate
        self.performedBy = performedBy
        self.laborCost = laborCost
        self.mileageAtService = mileageAtService
        self.workNotes = workNotes
        self.recommendations = recommendations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var formattedLaborCost: String {
        String(format: "₹%.2f", laborCost)
    }
}

// MARK: - Part Usage Model (Matches DB `maintenance_record_parts` table)

struct MaintenanceRecordPart: Identifiable, Codable, Hashable {
    let id: UUID
    var maintenanceRecordId: UUID?
    var partId: UUID?
    var quantity: Int
    var unitPriceAtTime: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case maintenanceRecordId = "maintenance_record_id"
        case partId = "part_id"
        case quantity
        case unitPriceAtTime = "unit_price_at_time"
    }
    
    init(
        id: UUID = UUID(),
        maintenanceRecordId: UUID? = nil,
        partId: UUID? = nil,
        quantity: Int,
        unitPriceAtTime: Double
    ) {
        self.id = id
        self.maintenanceRecordId = maintenanceRecordId
        self.partId = partId
        self.quantity = quantity
        self.unitPriceAtTime = unitPriceAtTime
    }
    
    var totalCost: Double {
        Double(quantity) * unitPriceAtTime
    }
}

// MARK: - Mock Data
extension MaintenanceRecord {
    static let mockRecord1 = MaintenanceRecord(
        vehicleId: Vehicle.mockVehicle1.id,
        type: .scheduledService,
        status: .completed,
        title: "Routine Oil Change",
        description: "Regular 10,000 km service",
        scheduledDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
        completedDate: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
        laborCost: 500.0,
        mileageAtService: 12000.0,
        workNotes: "Oil and filter replaced successfully"
    )
    
    static let mockRecord2 = MaintenanceRecord(
        vehicleId: Vehicle.mockVehicle2.id,
        type: .repair,
        status: .inProgress,
        title: "Brake System Repair",
        description: "Front brake pads replacement",
        scheduledDate: Date(),
        startedDate: Date(),
        laborCost: 1500.0,
        mileageAtService: 45000.0
    )
    
    static let mockRecords: [MaintenanceRecord] = [
        mockRecord1,
        mockRecord2
    ]
}
