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
    case active = "active"
    case inactive = "inactive"
    case maintenance = "maintenance"
    case retired = "retired"
    case inTransit = "in_transit"
}

enum VehicleType: String, Codable, CaseIterable {
    case truck = "Truck"
    case van = "Van"
    case car = "Car"
    case bus = "Bus"
    case motorcycle = "Motorcycle"
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
    
    // Live tracking data
    var currentSpeed: Double
    var fuelLevel: Double
    var totalMileage: Double
    var averageFuelEfficiency: Double
    
    // Location (flat columns in DB, not nested)
    var latitude: Double?
    var longitude: Double?
    var address: String?
    var lastLocationUpdate: Date?
    
    // Assignment
    var assignedDriverId: UUID?
    var assignedDriverName: String?
    
    // Maintenance
    var nextServiceDue: Date?
    var lastServiceDate: Date?
    
    // Additional details
    var yearOfManufacture: Int?
    var vinNumber: String?
    var color: String?
    var capacity: String?
    
    // Additional DB columns
    var fuelType: String?
    var registrationDate: Date?
    var vin: String?
    var mileage: String?
    var insuranceStatus: String?
    var lastService: String?
    
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
        case currentSpeed = "current_speed"
        case fuelLevel = "fuel_level"
        case totalMileage = "total_mileage"
        case averageFuelEfficiency = "average_fuel_efficiency"
        case latitude
        case longitude
        case address
        case lastLocationUpdate = "last_location_update"
        case assignedDriverId = "assigned_driver_id"
        case assignedDriverName = "assigned_driver_name"
        case nextServiceDue = "next_service_due"
        case lastServiceDate = "last_service_date"
        case yearOfManufacture = "year_of_manufacture"
        case vinNumber = "vin_number"
        case color
        case capacity
        case fuelType = "fuel_type"
        case registrationDate = "registration_date"
        case vin
        case mileage
        case insuranceStatus = "insurance_status"
        case lastService = "last_service"
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
        currentSpeed: Double = 0,
        fuelLevel: Double = 100,
        totalMileage: Double = 0,
        averageFuelEfficiency: Double = 0,
        latitude: Double? = nil,
        longitude: Double? = nil,
        address: String? = nil,
        lastLocationUpdate: Date? = nil,
        assignedDriverId: UUID? = nil,
        assignedDriverName: String? = nil,
        nextServiceDue: Date? = nil,
        lastServiceDate: Date? = nil,
        yearOfManufacture: Int? = nil,
        vinNumber: String? = nil,
        color: String? = nil,
        capacity: String? = nil,
        fuelType: String? = "Diesel",
        registrationDate: Date? = nil,
        vin: String? = "UNKNOWN",
        mileage: String? = "0 km",
        insuranceStatus: String? = "Pending",
        lastService: String? = "Never",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.registrationNumber = registrationNumber
        self.model = model
        self.manufacturer = manufacturer
        self.vehicleType = vehicleType
        self.status = status
        self.currentSpeed = currentSpeed
        self.fuelLevel = fuelLevel
        self.totalMileage = totalMileage
        self.averageFuelEfficiency = averageFuelEfficiency
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.lastLocationUpdate = lastLocationUpdate
        self.assignedDriverId = assignedDriverId
        self.assignedDriverName = assignedDriverName
        self.nextServiceDue = nextServiceDue
        self.lastServiceDate = lastServiceDate
        self.yearOfManufacture = yearOfManufacture
        self.vinNumber = vinNumber
        self.color = color
        self.capacity = capacity
        self.fuelType = fuelType
        self.registrationDate = registrationDate
        self.vin = vin
        self.mileage = mileage
        self.insuranceStatus = insuranceStatus
        self.lastService = lastService
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
            timestamp: lastLocationUpdate ?? Date()
        )
    }
    
    var formattedMileage: String {
        String(format: "%.1f km", totalMileage)
    }
    
    var formattedEfficiency: String {
        String(format: "%.1f km/l", averageFuelEfficiency)
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
        currentSpeed: 45.0,
        fuelLevel: 75.0,
        totalMileage: 12500.5,
        averageFuelEfficiency: 12.5,
        latitude: 19.0760,
        longitude: 72.8777,
        address: "Mumbai, Maharashtra",
        yearOfManufacture: 2021,
        color: "White",
        capacity: "1.5 Ton"
    )
    
    static let mockVehicle2 = Vehicle(
        registrationNumber: "DL-01-XY-5678",
        model: "LPT 1613",
        manufacturer: "Tata",
        vehicleType: .truck,
        status: .maintenance,
        currentSpeed: 0.0,
        fuelLevel: 45.0,
        totalMileage: 45000.0,
        averageFuelEfficiency: 6.5,
        latitude: 28.6139,
        longitude: 77.2090,
        address: "Delhi",
        yearOfManufacture: 2019,
        color: "Yellow",
        capacity: "10 Ton"
    )
    
    static let mockVehicles: [Vehicle] = [
        mockVehicle1,
        mockVehicle2
    ]
}
