//
//  ServiceSchedule.swift
//  FleetTrack
//
//  Created by FleetTrack on 08/01/26.
//

import Foundation

enum ServiceInterval: String, Codable, CaseIterable {
    case mileageBased = "Mileage Based"
    case timeBased = "Time Based"
    case both = "Both"
}

enum ScheduleStatus: String, Codable, CaseIterable {
    case upcoming = "Upcoming"
    case due = "Due"
    case overdue = "Overdue"
    case completed = "Completed"
}

struct ServiceSchedule: Identifiable, Codable, Hashable {
    let id: UUID
    var vehicleId: UUID
    var serviceType: String // e.g., "Oil Change", "Tire Rotation", "Brake Inspection"
    
    // Interval settings
    var intervalType: ServiceInterval
    var mileageInterval: Double? // in km
    var timeInterval: Int? // in days
    
    // Next service tracking
    var nextServiceDate: Date?
    var nextServiceMileage: Double?
    
    // Last service tracking
    var lastServiceDate: Date?
    var lastServiceMileage: Double?
    var lastMaintenanceRecordId: UUID?
    
    // Status
    var isActive: Bool
    var status: ScheduleStatus {
        guard isActive else { return .completed }
        
        if let nextDate = nextServiceDate {
            let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day ?? 0
            if daysUntilDue < 0 {
                return .overdue
            } else if daysUntilDue <= 7 {
                return .due
            }
        }
        
        return .upcoming
    }
    
    // Metadata
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        vehicleId: UUID,
        serviceType: String,
        intervalType: ServiceInterval,
        mileageInterval: Double? = nil,
        timeInterval: Int? = nil,
        nextServiceDate: Date? = nil,
        nextServiceMileage: Double? = nil,
        lastServiceDate: Date? = nil,
        lastServiceMileage: Double? = nil,
        lastMaintenanceRecordId: UUID? = nil,
        isActive: Bool = true,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vehicleId = vehicleId
        self.serviceType = serviceType
        self.intervalType = intervalType
        self.mileageInterval = mileageInterval
        self.timeInterval = timeInterval
        self.nextServiceDate = nextServiceDate
        self.nextServiceMileage = nextServiceMileage
        self.lastServiceDate = lastServiceDate
        self.lastServiceMileage = lastServiceMileage
        self.lastMaintenanceRecordId = lastMaintenanceRecordId
        self.isActive = isActive
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Helper to calculate days until due
    var daysUntilDue: Int? {
        guard let nextDate = nextServiceDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day
    }
    
    // Helper to calculate km until due
    var kmUntilDue: Double? {
        guard let nextMileage = nextServiceMileage else { return nil }
        // This would need current vehicle mileage to calculate properly
        return nextMileage
    }
}

// MARK: - Mock Data
extension ServiceSchedule {
    static let mockSchedule1 = ServiceSchedule(
        vehicleId: Vehicle.mockVehicle1.id,
        serviceType: "Oil Change",
        intervalType: .mileageBased,
        mileageInterval: 5000,
        nextServiceDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
        nextServiceMileage: 50000,
        lastServiceDate: Calendar.current.date(byAdding: .day, value: -23, to: Date()),
        lastServiceMileage: 45000,
        lastMaintenanceRecordId: MaintenanceRecord.mockRecord1.id,
        notes: "Use synthetic oil"
    )
    
    static let mockSchedule2 = ServiceSchedule(
        vehicleId: Vehicle.mockVehicle1.id,
        serviceType: "Tire Rotation",
        intervalType: .both,
        mileageInterval: 10000,
        timeInterval: 180,
        nextServiceDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()),
        nextServiceMileage: 55000,
        lastServiceDate: Calendar.current.date(byAdding: .day, value: -135, to: Date()),
        lastServiceMileage: 45000
    )
    
    static let mockSchedule3 = ServiceSchedule(
        vehicleId: Vehicle.mockVehicle2.id,
        serviceType: "Annual Inspection",
        intervalType: .timeBased,
        timeInterval: 365,
        nextServiceDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
        lastServiceDate: Calendar.current.date(byAdding: .day, value: -370, to: Date()),
        notes: "State required annual safety inspection"
    )
    
    static let mockSchedules: [ServiceSchedule] = [
        mockSchedule1,
        mockSchedule2,
        mockSchedule3
    ]
}
