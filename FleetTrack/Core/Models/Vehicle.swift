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
