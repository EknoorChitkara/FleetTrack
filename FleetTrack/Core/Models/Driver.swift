//
//  Driver.swift
//  FleetTrack
//
//  Created by FleetTrack on 08/01/26.
//

import Foundation

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
    var totalDistanceDriven: Double // in km
    
    // Assignment
    var currentVehicleId: UUID?
    var currentTripId: UUID?
    
    // Additional certifications
    var certifications: [String] // e.g., "First Aid", "Defensive Driving"
    var yearsOfExperience: Int
    
    // Emergency contact
    var emergencyContactName: String?
    var emergencyContactPhone: String?
    
    // Availability
    var isActive: Bool
    var joinedDate: Date
    var lastActiveDate: Date
    
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
    
    // Computed properties
    var formattedRating: String {
        String(format: "%.1f", rating)
    }
    
    var averageDistancePerTrip: Double {
        guard totalTrips > 0 else { return 0 }
        return totalDistanceDriven / Double(totalTrips)
    }
    
    var formattedAverageDistance: String {
        String(format: "%.1f km", averageDistancePerTrip)
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

// MARK: - Mock Data
extension Driver {
    static let mockDriver1 = Driver(
        userId: User.mockDriver.id,
        driverLicenseNumber: "DL-1420110012345",
        licenseType: .transport,
        licenseExpiryDate: Calendar.current.date(byAdding: .year, value: 2, to: Date())!,
        status: .onTrip,
        rating: 4.7,
        safetyScore: 92,
        totalTrips: 342,
        totalDistanceDriven: 18750.5,
        currentVehicleId: Vehicle.mockVehicle1.id,
        currentTripId: Trip.mockOngoingTrip.id,
        certifications: ["First Aid Certified", "Defensive Driving", "Hazmat Handling"],
        yearsOfExperience: 8,
        emergencyContactName: "Sunita Kumar",
        emergencyContactPhone: "+91 98765 43211",
        joinedDate: Calendar.current.date(byAdding: .year, value: -3, to: Date())!
    )
    
    static let mockDriver2 = Driver(
        userId: UUID(),
        driverLicenseNumber: "DL-1420110067890",
        licenseType: .heavyMotorVehicle,
        licenseExpiryDate: Calendar.current.date(byAdding: .day, value: 25, to: Date())!,
        status: .available,
        rating: 4.9,
        safetyScore: 98,
        totalTrips: 567,
        totalDistanceDriven: 45230.0,
        certifications: ["Advanced Driving", "First Aid Certified"],
        yearsOfExperience: 12,
        emergencyContactName: "Anita Sharma",
        emergencyContactPhone: "+91 98765 11111",
        joinedDate: Calendar.current.date(byAdding: .year, value: -5, to: Date())!
    )
    
    static let mockDriver3 = Driver(
        userId: UUID(),
        driverLicenseNumber: "DL-0720110034567",
        licenseType: .lightMotorVehicle,
        licenseExpiryDate: Calendar.current.date(byAdding: .month, value: 8, to: Date())!,
        status: .offDuty,
        rating: 4.3,
        safetyScore: 85,
        totalTrips: 128,
        totalDistanceDriven: 6240.0,
        certifications: ["First Aid Certified"],
        yearsOfExperience: 3,
        emergencyContactName: "Ravi Verma",
        emergencyContactPhone: "+91 98765 22222",
        joinedDate: Calendar.current.date(byAdding: .year, value: -1, to: Date())!
    )
    
    static let mockDrivers: [Driver] = [
        mockDriver1,
        mockDriver2,
        mockDriver3
    ]
}
