//
//  MaintenancePersonnel.swift
//  FleetTrack
//
//  Created by FleetTrack on 08/01/26.
//

import Foundation

enum MaintenancePersonnelStatus: String, Codable, CaseIterable {
    case available = "Available"
    case working = "Working"
    case onBreak = "On Break"
    case offDuty = "Off Duty"
}

enum ExpertiseLevel: String, Codable, CaseIterable {
    case junior = "Junior"
    case intermediate = "Intermediate"
    case senior = "Senior"
    case expert = "Expert"
}

enum SpecializationArea: String, Codable, CaseIterable {
    case engine = "Engine"
    case transmission = "Transmission"
    case electrical = "Electrical"
    case brakes = "Brakes"
    case bodyWork = "Body Work"
    case diagnostics = "Diagnostics"
    case general = "General Maintenance"
}

struct MaintenancePersonnel: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID // Reference to User model
    
    // Professional info
    var employeeId: String
    var status: MaintenancePersonnelStatus
    var expertiseLevel: ExpertiseLevel
    var specializations: [SpecializationArea]
    
    // Certifications and qualifications
    var certifications: [String] // e.g., "ASE Certified", "Diesel Mechanic"
    var yearsOfExperience: Int
    
    // Performance metrics
    var totalJobsCompleted: Int
    var averageJobCompletionTime: Double // in hours
    var customerRating: Double // 0.0 to 5.0
    
    // Current work
    var currentMaintenanceRecordId: UUID?
    var currentVehicleId: UUID?
    
    // Shift information
    var shiftStartTime: String? // e.g., "09:00"
    var shiftEndTime: String? // e.g., "18:00"
    var workingDays: [String] // e.g., ["Monday", "Tuesday", "Wednesday"]
    
    // Pay information (optional)
    var hourlyRate: Double?
    
    // Availability
    var isActive: Bool
    var joinedDate: Date
    var lastActiveDate: Date
    
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        employeeId: String,
        status: MaintenancePersonnelStatus = .available,
        expertiseLevel: ExpertiseLevel = .intermediate,
        specializations: [SpecializationArea] = [.general],
        certifications: [String] = [],
        yearsOfExperience: Int = 0,
        totalJobsCompleted: Int = 0,
        averageJobCompletionTime: Double = 0,
        customerRating: Double = 0.0,
        currentMaintenanceRecordId: UUID? = nil,
        currentVehicleId: UUID? = nil,
        shiftStartTime: String? = nil,
        shiftEndTime: String? = nil,
        workingDays: [String] = [],
        hourlyRate: Double? = nil,
        isActive: Bool = true,
        joinedDate: Date = Date(),
        lastActiveDate: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.employeeId = employeeId
        self.status = status
        self.expertiseLevel = expertiseLevel
        self.specializations = specializations
        self.certifications = certifications
        self.yearsOfExperience = yearsOfExperience
        self.totalJobsCompleted = totalJobsCompleted
        self.averageJobCompletionTime = averageJobCompletionTime
        self.customerRating = customerRating
        self.currentMaintenanceRecordId = currentMaintenanceRecordId
        self.currentVehicleId = currentVehicleId
        self.shiftStartTime = shiftStartTime
        self.shiftEndTime = shiftEndTime
        self.workingDays = workingDays
        self.hourlyRate = hourlyRate
        self.isActive = isActive
        self.joinedDate = joinedDate
        self.lastActiveDate = lastActiveDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed properties
    var formattedRating: String {
        String(format: "%.1f", customerRating)
    }
    
    var formattedAverageJobTime: String {
        let hours = Int(averageJobCompletionTime)
        let minutes = Int((averageJobCompletionTime - Double(hours)) * 60)
        return String(format: "%dh %dm", hours, minutes)
    }
    
    var specializationsString: String {
        specializations.map { $0.rawValue }.joined(separator: ", ")
    }
    
    var isCurrentlyWorking: Bool {
        status == .working && currentMaintenanceRecordId != nil
    }
    
    var shiftSchedule: String? {
        guard let start = shiftStartTime, let end = shiftEndTime else { return nil }
        return "\(start) - \(end)"
    }
    
    var formattedHourlyRate: String? {
        guard let rate = hourlyRate else { return nil }
        return String(format: "₹%.2f/hr", rate)
    }
}

// MARK: - Mock Data
extension MaintenancePersonnel {
    static let mockPersonnel1 = MaintenancePersonnel(
        userId: User.mockMaintenancePersonnel.id,
        employeeId: "EMP-M-001",
        status: .working,
        expertiseLevel: .senior,
        specializations: [.engine, .transmission, .diagnostics],
        certifications: ["ASE Master Certified", "Diesel Engine Specialist", "Advanced Diagnostics"],
        yearsOfExperience: 12,
        totalJobsCompleted: 487,
        averageJobCompletionTime: 3.5,
        customerRating: 4.8,
        currentMaintenanceRecordId: MaintenanceRecord.mockRecord2.id,
        currentVehicleId: Vehicle.mockVehicle2.id,
        shiftStartTime: "08:00",
        shiftEndTime: "17:00",
        workingDays: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
        hourlyRate: 500.00,
        joinedDate: Calendar.current.date(byAdding: .year, value: -6, to: Date())!
    )
    
    static let mockPersonnel2 = MaintenancePersonnel(
        userId: UUID(),
        employeeId: "EMP-M-002",
        status: .available,
        expertiseLevel: .expert,
        specializations: [.electrical, .diagnostics],
        certifications: ["Automotive Electrician", "Electronic Systems Specialist"],
        yearsOfExperience: 15,
        totalJobsCompleted: 623,
        averageJobCompletionTime: 2.8,
        customerRating: 4.9,
        shiftStartTime: "09:00",
        shiftEndTime: "18:00",
        workingDays: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
        hourlyRate: 600.00,
        joinedDate: Calendar.current.date(byAdding: .year, value: -8, to: Date())!
    )
    
    static let mockPersonnel3 = MaintenancePersonnel(
        userId: UUID(),
        employeeId: "EMP-M-003",
        status: .available,
        expertiseLevel: .intermediate,
        specializations: [.brakes, .general],
        certifications: ["Brake Systems Certified", "General Maintenance"],
        yearsOfExperience: 5,
        totalJobsCompleted: 198,
        averageJobCompletionTime: 4.2,
        customerRating: 4.5,
        shiftStartTime: "10:00",
        shiftEndTime: "19:00",
        workingDays: ["Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
        hourlyRate: 400.00,
        joinedDate: Calendar.current.date(byAdding: .year, value: -2, to: Date())!
    )
    
    static let mockPersonnelList: [MaintenancePersonnel] = [
        mockPersonnel1,
        mockPersonnel2,
        mockPersonnel3
    ]
}
