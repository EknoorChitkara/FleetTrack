//
//  MaintenanceRecord.swift
//  FleetTrack
//
//  Professional Fleet Management System
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

// MARK: - Part Usage

struct PartUsage: Codable, Hashable {
    var partId: UUID
    var partName: String
    var quantity: Int
    var unitPrice: Double
    
    var totalCost: Double {
        Double(quantity) * unitPrice
    }
}

// MARK: - Maintenance Record Model

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
    
    // Costs
    var laborCost: Double
    var partsUsed: [PartUsage]
    
    var totalCost: Double {
        let partsCost = partsUsed.reduce(0) { $0 + $1.totalCost }
        return laborCost + partsCost
    }
    
    // Mileage at service
    var mileageAtService: Double?
    
    // Notes
    var workNotes: String?
    var recommendations: String?
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
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
        partsUsed: [PartUsage] = [],
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
        self.partsUsed = partsUsed
        self.mileageAtService = mileageAtService
        self.workNotes = workNotes
        self.recommendations = recommendations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var formattedTotalCost: String {
        String(format: "₹%.2f", totalCost)
    }
}
