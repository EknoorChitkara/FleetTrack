//
//  Vehicle.swift
//  FleetTrack
//
//  Created by FleetTrack on 08/01/26.
//

import Foundation

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

struct Vehicle: Identifiable, Codable, Hashable {
    let id: UUID
    var registrationNumber: String
    var model: String
    var manufacturer: String
    var vehicleType: VehicleType
    var status: VehicleStatus
    
    // Live tracking data
    var currentSpeed: Double // in km/h
    var fuelLevel: Double // percentage (0-100)
    var totalMileage: Double // in km
    var averageFuelEfficiency: Double // km/l
    
    // Location tracking
    var currentLocation: Location?
    var lastUpdated: Date
    
    // Assignment
    var assignedDriverId: UUID?
    
    // Maintenance info
    var nextServiceDue: Date?
    var lastServiceDate: Date?
    
    // Additional details
    var yearOfManufacture: Int?
    var vinNumber: String?
    var color: String?
    var capacity: String? // e.g., "1000 kg", "15 passengers"
    
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
    
    // Formatted mileage
    var formattedMileage: String {
        String(format: "%.1f km", totalMileage)
    }
    
    // Formatted fuel efficiency
    var formattedEfficiency: String {
        String(format: "%.1f km/l", averageFuelEfficiency)
    }
}

struct Location: Codable, Hashable {
    var latitude: Double
    var longitude: Double
    var address: String
    var lastUpdated: Date
    
    init(
        latitude: Double,
        longitude: Double,
        address: String,
        lastUpdated: Date = Date()
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Mock Data
extension Vehicle {
    static let mockVehicle1 = Vehicle(
        registrationNumber: "DL-01-AB-1234",
        model: "Ace",
        manufacturer: "Tata",
        vehicleType: .lightCommercial,
        status: .active,
        currentSpeed: 45,
        fuelLevel: 75,
        totalMileage: 45230,
        averageFuelEfficiency: 18.5,
        currentLocation: Location(
            latitude: 28.5355,
            longitude: 77.3910,
            address: "Sector 18, Noida"
        ),
        assignedDriverId: User.mockDriver.id,
        nextServiceDue: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
        lastServiceDate: Calendar.current.date(byAdding: .day, value: -23, to: Date()),
        yearOfManufacture: 2022,
        color: "White",
        capacity: "1000 kg"
    )
    
    static let mockVehicle2 = Vehicle(
        registrationNumber: "DL-02-CD-5678",
        model: "Prima LX",
        manufacturer: "Tata",
        vehicleType: .heavyCommercial,
        status: .inMaintenance,
        currentSpeed: 0,
        fuelLevel: 50,
        totalMileage: 125000,
        averageFuelEfficiency: 12.3,
        assignedDriverId: nil,
        nextServiceDue: Date(),
        lastServiceDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()),
        yearOfManufacture: 2020,
        color: "Blue",
        capacity: "5000 kg"
    )
    
    static let mockVehicle3 = Vehicle(
        registrationNumber: "DL-03-EF-9101",
        model: "Magic",
        manufacturer: "Tata",
        vehicleType: .passenger,
        status: .active,
        currentSpeed: 32,
        fuelLevel: 90,
        totalMileage: 67500,
        averageFuelEfficiency: 15.2,
        currentLocation: Location(
            latitude: 28.4595,
            longitude: 77.0266,
            address: "Gurgaon Sector 29"
        ),
        nextServiceDue: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
        lastServiceDate: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
        yearOfManufacture: 2021,
        color: "Yellow",
        capacity: "12 passengers"
    )
    
    static let mockVehicles: [Vehicle] = [
        mockVehicle1,
        mockVehicle2,
        mockVehicle3
    ]
}
