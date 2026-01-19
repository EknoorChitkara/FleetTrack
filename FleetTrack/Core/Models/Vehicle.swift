//
//  Vehicle.swift
//  FleetTrack
//
//  Professional Fleet Management System
//  Updated to match database schema
//

import Foundation

// MARK: - Enums

enum VehicleStatus: String, Codable, CaseIterable {
    case active = "Active"
    case inactive = "Inactive"
    case inMaintenance = "Maintenance"  // Changed to match DB enum
    case retired = "Retired"  // Added from DB enum
}

public enum VehicleType: String, Codable, CaseIterable {
    case truck = "Truck"
    case van = "Van"
    case car = "Car"
    case other = "Other"
}

// MARK: - Location Model (for convenience, not stored in DB)

struct Location: Codable, Hashable {
    var latitude: Double
    var longitude: Double
    var address: String
    var timestamp: Date

    init(
        latitude: Double,
        longitude: Double,
        address: String,
        timestamp: Date = Date()
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.timestamp = timestamp
    }
}

// MARK: - Vehicle Model (Matches DB Schema)

struct Vehicle: Identifiable, Codable, Hashable {
    let id: UUID
    var registrationNumber: String
    var model: String
    var manufacturer: String
    var vehicleType: VehicleType
    var status: VehicleStatus

    // Location (from DB schema)
    var latitude: Double?
    var longitude: Double?
    var address: String?

    // Assignment (from DB schema)
    var assignedDriverId: UUID?
    var assignedDriverName: String?

    // Vehicle Details (from DB schema)
    var vin: String?
    var mileage: Double?
    var capacity: String?
    var tankCapacity: Double? // in Liters
    var fuelType: String?
    var registrationDate: Date?
    
    // Insurance (from DB schema)
    var insuranceStatus: String?
    var insuranceExpiry: Date?
    
    // Maintenance (from DB schema)
    var lastService: Date?
    var nextServiceDue: Date?
    
    // Status
    var isActive: Bool?

    // Timestamps
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case registrationNumber = "registration_number"
        case model
        case manufacturer
        case vehicleType = "vehicle_type"
        case status
        case latitude
        case longitude
        case address
        case assignedDriverId = "assigned_driver_id"
        case assignedDriverName = "assigned_driver_name"
        case vin
        case mileage
        case capacity
        case tankCapacity = "tank_capacity"
        case fuelType = "fuel_type"
        case registrationDate = "registration_date"
        case insuranceStatus = "insurance_status"
        case insuranceExpiry = "insurance_expiry"
        case lastService = "last_service"
        case nextServiceDue = "next_service_due"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        registrationNumber: String,
        model: String,
        manufacturer: String,
        vehicleType: VehicleType,
        status: VehicleStatus = .active,
        latitude: Double? = nil,
        longitude: Double? = nil,
        address: String? = nil,
        assignedDriverId: UUID? = nil,
        assignedDriverName: String? = nil,
        vin: String? = nil,
        mileage: Double? = 0,
        capacity: String? = nil,
        tankCapacity: Double? = 60.0,
        fuelType: String? = "Diesel",
        registrationDate: Date? = nil,
        insuranceStatus: String? = "Valid",
        insuranceExpiry: Date? = nil,
        lastService: Date? = nil,
        nextServiceDue: Date? = nil,
        isActive: Bool? = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.registrationNumber = registrationNumber
        self.model = model
        self.manufacturer = manufacturer
        self.vehicleType = vehicleType
        self.status = status
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.assignedDriverId = assignedDriverId
        self.assignedDriverName = assignedDriverName
        self.vin = vin
        self.mileage = mileage
        self.capacity = capacity
        self.tankCapacity = tankCapacity
        self.fuelType = fuelType
        self.registrationDate = registrationDate
        self.insuranceStatus = insuranceStatus
        self.insuranceExpiry = insuranceExpiry
        self.lastService = lastService
        self.nextServiceDue = nextServiceDue
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Convenience property to get location as Location object
    var currentLocation: Location? {
        guard let lat = latitude, let lng = longitude else { return nil }
        return Location(
            latitude: lat,
            longitude: lng,
            address: address ?? "",
            timestamp: Date()
        )
    }

    var isServiceDue: Bool {
        guard let nextService = nextServiceDue else { return false }
        return nextService <= Date()
    }
}

// MARK: - Mock Data
extension Vehicle {
    static let mockVehicle1 = Vehicle(
        registrationNumber: "MH-01-AB-1234",
        model: "Bolero",
        manufacturer: "Mahindra",
        vehicleType: .van,
        status: .active,
        latitude: 19.0760,
        longitude: 72.8777,
        address: "Mumbai, Maharashtra",
        mileage: 12500.5,
        capacity: "1.5 Ton",
        tankCapacity: 60.0
    )

    static let mockVehicle2 = Vehicle(
        registrationNumber: "DL-01-XY-5678",
        model: "LPT 1613",
        manufacturer: "Tata",
        vehicleType: .truck,
        status: .inMaintenance,
        latitude: 28.6139,
        longitude: 77.2090,
        address: "Delhi",
        mileage: 45000.0,
        capacity: "10 Ton",
        tankCapacity: 160.0
    )

    static let mockVehicles: [Vehicle] = [
        mockVehicle1,
        mockVehicle2,
    ]
}
