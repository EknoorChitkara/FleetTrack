//
//  Vehicle.swift
//  FleetTrack
//
//  Professional Fleet Management System
//

import Foundation

// MARK: - Enums

enum VehicleStatus: String, Codable, CaseIterable {
    case active = "Active"
    case inMaintenance = "In Maintenance"
    case inactive = "Inactive"
    case outOfService = "Out of Service"
}

enum VehicleType: String, Codable, CaseIterable {
    case lightCommercial = "Light Commercial"
    case heavyCommercial = "Heavy Commercial"
    case passenger = "Passenger"
    case specialized = "Specialized"
}

// MARK: - Location Model

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

// MARK: - Vehicle Model

struct Vehicle: Identifiable, Codable, Hashable {
    let id: UUID
    var registrationNumber: String
    var model: String
    var manufacturer: String
    var vehicleType: VehicleType
    var status: VehicleStatus
    
    // Live tracking data
    var currentSpeed: Double // km/h
    var fuelLevel: Double // percentage (0-100)
    var totalMileage: Double // km
    var averageFuelEfficiency: Double // km/l
    
    // Location
    var currentLocation: Location?
    var lastUpdated: Date
    
    // Assignment
    var assignedDriverId: UUID?
    
    // Maintenance
    var nextServiceDue: Date?
    var lastServiceDate: Date?
    
    // Additional details
    var yearOfManufacture: Int?
    var vinNumber: String?
    var color: String?
    var capacity: String?
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
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
        currentLocation: Location? = nil,
        lastUpdated: Date = Date(),
        assignedDriverId: UUID? = nil,
        nextServiceDue: Date? = nil,
        lastServiceDate: Date? = nil,
        yearOfManufacture: Int? = nil,
        vinNumber: String? = nil,
        color: String? = nil,
        capacity: String? = nil,
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
        self.currentLocation = currentLocation
        self.lastUpdated = lastUpdated
        self.assignedDriverId = assignedDriverId
        self.nextServiceDue = nextServiceDue
        self.lastServiceDate = lastServiceDate
        self.yearOfManufacture = yearOfManufacture
        self.vinNumber = vinNumber
        self.color = color
        self.capacity = capacity
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
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
        vehicleType: .lightCommercial,
        status: .active,
        currentSpeed: 45.0,
        fuelLevel: 75.0,
        totalMileage: 12500.5,
        averageFuelEfficiency: 12.5,
        currentLocation: Location(latitude: 19.0760, longitude: 72.8777, address: "Mumbai, Maharashtra"),
        yearOfManufacture: 2021,
        color: "White",
        capacity: "1.5 Ton"
    )
    
    static let mockVehicle2 = Vehicle(
        registrationNumber: "DL-01-XY-5678",
        model: "LPT 1613",
        manufacturer: "Tata",
        vehicleType: .heavyCommercial,
        status: .inMaintenance,
        currentSpeed: 0.0,
        fuelLevel: 45.0,
        totalMileage: 45000.0,
        averageFuelEfficiency: 6.5,
        currentLocation: Location(latitude: 28.6139, longitude: 77.2090, address: "Delhi"),
        yearOfManufacture: 2019,
        color: "Yellow",
        capacity: "10 Ton"
    )
    
    static let mockVehicles: [Vehicle] = [
        mockVehicle1,
        mockVehicle2
    ]
}
