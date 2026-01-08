//
//  Driver.swift
//  FleetTrack
//
//  Professional Fleet Management System
//

import Foundation

// MARK: - Enums

enum DriverStatus: String, Codable, CaseIterable {
    case available = "Available"
    case onTrip = "On Trip"
    case offDuty = "Off Duty"
    case onLeave = "On Leave"
}

enum LicenseType: String, Codable, CaseIterable {
    case lightMotorVehicle = "Light Motor Vehicle"
    case heavyMotorVehicle = "Heavy Motor Vehicle"
    case transport = "Transport"
    case hazardousMaterials = "Hazardous Materials"
}

// MARK: - Driver Model

struct Driver: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID // Reference to User model
    
    // Driver-specific info
    var driverLicenseNumber: String
    var licenseType: LicenseType
    var licenseExpiryDate: Date
    var status: DriverStatus
    
    // Performance metrics
    var rating: Double // 0.0 to 5.0
    var safetyScore: Int // 0 to 100
    var totalTrips: Int
    var totalDistanceDriven: Double // km
    
    // Current assignment
    var currentVehicleId: UUID?
    var currentTripId: UUID?
    
    // Certifications
    var certifications: [String]
    var yearsOfExperience: Int
    
    // Emergency contact
    var emergencyContactName: String?
    var emergencyContactPhone: String?
    
    // Status
    var isActive: Bool
    var joinedDate: Date
    var lastActiveDate: Date
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        driverLicenseNumber: String,
        licenseType: LicenseType,
        licenseExpiryDate: Date,
        status: DriverStatus = .available,
        rating: Double = 0.0,
        safetyScore: Int = 100,
        totalTrips: Int = 0,
        totalDistanceDriven: Double = 0,
        currentVehicleId: UUID? = nil,
        currentTripId: UUID? = nil,
        certifications: [String] = [],
        yearsOfExperience: Int = 0,
        emergencyContactName: String? = nil,
        emergencyContactPhone: String? = nil,
        isActive: Bool = true,
        joinedDate: Date = Date(),
        lastActiveDate: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.driverLicenseNumber = driverLicenseNumber
        self.licenseType = licenseType
        self.licenseExpiryDate = licenseExpiryDate
        self.status = status
        self.rating = rating
        self.safetyScore = safetyScore
        self.totalTrips = totalTrips
        self.totalDistanceDriven = totalDistanceDriven
        self.currentVehicleId = currentVehicleId
        self.currentTripId = currentTripId
        self.certifications = certifications
        self.yearsOfExperience = yearsOfExperience
        self.emergencyContactName = emergencyContactName
        self.emergencyContactPhone = emergencyContactPhone
        self.isActive = isActive
        self.joinedDate = joinedDate
        self.lastActiveDate = lastActiveDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var formattedRating: String {
        String(format: "%.1f", rating)
    }
    
    var averageDistancePerTrip: Double {
        guard totalTrips > 0 else { return 0 }
        return totalDistanceDriven / Double(totalTrips)
    }
    
    var isLicenseExpiringSoon: Bool {
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: licenseExpiryDate).day ?? 0
        return daysUntilExpiry <= 30 && daysUntilExpiry >= 0
    }
    
    var isLicenseExpired: Bool {
        licenseExpiryDate < Date()
    }
    
    var licenseStatus: String {
        if isLicenseExpired {
            return "Expired"
        } else if isLicenseExpiringSoon {
            return "Expiring Soon"
        } else {
            return "Valid"
        }
    }
}
