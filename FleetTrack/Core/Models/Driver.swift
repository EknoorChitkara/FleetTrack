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
    var userId: UUID
    
    // Driver Info (Added from DB Schema)
    var fullName: String
    var email: String
    var phoneNumber: String?
    var address: String?
    var licenseNumber: String?
    
    // Driver-specific info
    var driverLicenseNumber: String?
    var licenseType: LicenseType?
    var licenseExpiryDate: Date?
    var status: DriverStatus?
    
    // Performance metrics
    var rating: Double?
    var safetyScore: Int?
    var totalTrips: Int?
    var totalDistanceDriven: Double?
    var onTimeDeliveryRate: Double?
    var fuelEfficiency: Double?
    
    // Current assignment
    var currentVehicleId: UUID?
    var currentTripId: UUID?
    
    // Certifications
    var certifications: [String]?
    var yearsOfExperience: Int?
    
    // Emergency contact
    var emergencyContactName: String?
    var emergencyContactPhone: String?
    
    // Status
    var isActive: Bool?
    var joinedDate: Date?
    var lastActiveDate: Date?
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fullName = "full_name"
        case email
        case phoneNumber = "phone_number"
        case address
        case licenseNumber = "license_number"
        case driverLicenseNumber = "driver_license_number"
        case licenseType = "license_type"
        case licenseExpiryDate = "license_expiry_date"
        case status
        case rating
        case safetyScore = "safety_score"
        case totalTrips = "total_trips"
        case totalDistanceDriven = "total_distance_driven"
        case onTimeDeliveryRate = "on_time_delivery_rate"
        case fuelEfficiency = "fuel_efficiency"
        case currentVehicleId = "current_vehicle_id"
        case currentTripId = "current_trip_id"
        case certifications
        case yearsOfExperience = "years_of_experience"
        case emergencyContactName = "emergency_contact_name"
        case emergencyContactPhone = "emergency_contact_phone"
        case isActive = "is_active"
        case joinedDate = "joined_date"
        case lastActiveDate = "last_active_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        fullName: String = "",
        email: String = "",
        phoneNumber: String? = nil,
        address: String? = nil,
        licenseNumber: String? = nil,
        driverLicenseNumber: String? = nil,
        licenseType: LicenseType? = nil,
        licenseExpiryDate: Date? = nil,
        status: DriverStatus? = .available,
        rating: Double? = 0.0,
        safetyScore: Int? = 100,
        totalTrips: Int? = 0,
        totalDistanceDriven: Double? = 0,
        onTimeDeliveryRate: Double? = 0,
        fuelEfficiency: Double? = 0,
        currentVehicleId: UUID? = nil,
        currentTripId: UUID? = nil,
        certifications: [String]? = [],
        yearsOfExperience: Int? = 0,
        emergencyContactName: String? = nil,
        emergencyContactPhone: String? = nil,
        isActive: Bool? = true,
        joinedDate: Date? = nil,
        lastActiveDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.fullName = fullName
        self.email = email
        self.phoneNumber = phoneNumber
        self.address = address
        self.licenseNumber = licenseNumber
        self.driverLicenseNumber = driverLicenseNumber
        self.licenseType = licenseType
        self.licenseExpiryDate = licenseExpiryDate
        self.status = status
        self.rating = rating
        self.safetyScore = safetyScore
        self.totalTrips = totalTrips
        self.totalDistanceDriven = totalDistanceDriven
        self.onTimeDeliveryRate = onTimeDeliveryRate
        self.fuelEfficiency = fuelEfficiency
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
        String(format: "%.1f", rating ?? 0.0)
    }
    
    var averageDistancePerTrip: Double {
        let trips = totalTrips ?? 0
        let distance = totalDistanceDriven ?? 0
        guard trips > 0 else { return 0 }
        return distance / Double(trips)
    }
    
    var isLicenseExpiringSoon: Bool {
        guard let expiryDate = licenseExpiryDate else { return false }
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        return daysUntilExpiry <= 30 && daysUntilExpiry >= 0
    }
    
    var isLicenseExpired: Bool {
        guard let expiryDate = licenseExpiryDate else { return false }
        return expiryDate < Date()
    }
    
    var licenseStatus: String {
        guard licenseExpiryDate != nil else { return "Unknown" }
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
        fullName: User.mockDriver.name,
        email: User.mockDriver.email,
        phoneNumber: User.mockDriver.phoneNumber,
        address: "123, Sector 15, Gurgaon, Haryana",
        licenseNumber: "DL-1420110012345",
        driverLicenseNumber: "DL-1420110012345",
        licenseType: .transport,
        licenseExpiryDate: Calendar.current.date(byAdding: .year, value: 2, to: Date())!,
        status: .onTrip,
        rating: 4.7,
        safetyScore: 92,
        totalTrips: 342,
        totalDistanceDriven: 18750.5,
        onTimeDeliveryRate: 98.5,
        fuelEfficiency: 7.2,
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
        fullName: "Anita Sharma",
        email: "anita.sharma@fleettrack.com",
        phoneNumber: "+91 98765 11111",
        address: "45, Park Street, Kolkata, WB",
        licenseNumber: "DL-1420110067890",
        driverLicenseNumber: "DL-1420110067890",
        licenseType: .heavyMotorVehicle,
        licenseExpiryDate: Calendar.current.date(byAdding: .day, value: 25, to: Date())!,
        status: .available,
        rating: 4.9,
        safetyScore: 98,
        totalTrips: 567,
        totalDistanceDriven: 45230.0,
        onTimeDeliveryRate: 99.2,
        fuelEfficiency: 6.8,
        certifications: ["Advanced Driving", "First Aid Certified"],
        yearsOfExperience: 12,
        emergencyContactName: "Anita Sharma",
        emergencyContactPhone: "+91 98765 11111",
        joinedDate: Calendar.current.date(byAdding: .year, value: -5, to: Date())!
    )
    
    static let mockDriver3 = Driver(
        userId: UUID(),
        fullName: "Ravi Verma",
        email: "ravi.verma@fleettrack.com",
        phoneNumber: "+91 98765 22222",
        address: "89, Mall Road, Shimla, HP",
        licenseNumber: "DL-0720110034567",
        driverLicenseNumber: "DL-0720110034567",
        licenseType: .lightMotorVehicle,
        licenseExpiryDate: Calendar.current.date(byAdding: .month, value: 8, to: Date())!,
        status: .offDuty,
        rating: 4.3,
        safetyScore: 85,
        totalTrips: 128,
        totalDistanceDriven: 6240.0,
        onTimeDeliveryRate: 92.0,
        fuelEfficiency: 8.5,
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
