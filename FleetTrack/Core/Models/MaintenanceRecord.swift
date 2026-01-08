//
//  MaintenanceRecord.swift
//  FleetTrack
//
//  Created by FleetTrack on 08/01/26.
//

import Foundation

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

struct PartUsage: Codable, Hashable {
    var partId: UUID
    var quantity: Int
    var unitPrice: Double
    
    var totalCost: Double {
        Double(quantity) * unitPrice
    }
}

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
    
    var formattedTotalCost: String {
        String(format: "₹%.2f", totalCost)
    }
}

// MARK: - Mock Data
extension MaintenanceRecord {
    static let mockRecord1 = MaintenanceRecord(
        vehicleId: Vehicle.mockVehicle1.id,
        type: .scheduledService,
        status: .completed,
        title: "Regular Service - 45,000 km",
        description: "Routine maintenance service",
        scheduledDate: Calendar.current.date(byAdding: .day, value: -23, to: Date())!,
        startedDate: Calendar.current.date(byAdding: .day, value: -23, to: Date())!,
        completedDate: Calendar.current.date(byAdding: .day, value: -23, to: Date())!,
        performedBy: UUID(), // Mock maintenance personnel ID
        laborCost: 1500.00,
        partsUsed: [
            PartUsage(partId: UUID(), quantity: 1, unitPrice: 450.00)
        ],
        mileageAtService: 45000,
        workNotes: "Changed engine oil and oil filter. All systems checked and working properly.",
        recommendations: "Next service due at 50,000 km"
    )
    
    static let mockRecord2 = MaintenanceRecord(
        vehicleId: Vehicle.mockVehicle2.id,
        type: .repair,
        status: .inProgress,
        title: "Brake System Repair",
        description: "Replace worn brake pads and rotors",
        scheduledDate: Date(),
        startedDate: Date(),
        performedBy: UUID(), // Mock maintenance personnel ID
        laborCost: 2000.00,
        partsUsed: [
            PartUsage(partId: UUID(), quantity: 2, unitPrice: 2500.00)
        ],
        mileageAtService: 125000,
        workNotes: "Front brake pads worn beyond safe limits. Replacing with new parts."
    )
    
    static let mockRecord3 = MaintenanceRecord(
        vehicleId: Vehicle.mockVehicle1.id,
        type: .scheduledService,
        status: .scheduled,
        title: "50,000 km Service",
        description: "Major service checkpoint",
        scheduledDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
        laborCost: 2500.00,
        mileageAtService: 50000
    )
    
    static let mockRecords: [MaintenanceRecord] = [
        mockRecord1,
        mockRecord2,
        mockRecord3
    ]
}
