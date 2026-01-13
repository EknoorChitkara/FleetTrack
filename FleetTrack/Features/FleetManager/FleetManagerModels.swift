//
//  FleetManagerModels.swift
//  FleetTrack
//
//  Created for Fleet Manager specific requirements
//

import Foundation
import SwiftUI

// MARK: - Enums

enum FuelType: String, Codable, CaseIterable {
    case petrol = "Petrol"
    case diesel = "Diesel"
    case electric = "Electric"
    case hybrid = "Hybrid"
    case cng = "CNG"
}

// MARK: - FM Models

struct FMVehicle: Identifiable, Codable {
    let id: UUID
    var registrationNumber: String
    var vehicleType: VehicleType
    var manufacturer: String
    var model: String
    var fuelType: FuelType
    var capacity: String
    var registrationDate: Date
    var status: VehicleStatus
    var assignedDriverId: UUID?
    var assignedDriverName: String?
    
    // Detailed Info
    var vin: String = "UNKNOWN"
    var mileage: String = "0 km"
    var insuranceStatus: String = "Pending"
    var lastService: String = "Never"
    var createdAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id
        case registrationNumber = "registration_number"
        case vehicleType = "vehicle_type"
        case manufacturer, model
        case fuelType = "fuel_type"
        case capacity
        case registrationDate = "registration_date"
        case status
        case assignedDriverId = "assigned_driver_id"
        case assignedDriverName = "assigned_driver_name"
        case vin, mileage
        case insuranceStatus = "insurance_status"
        case lastService = "last_service"
        case createdAt = "created_at"
    }
}

struct FMDriver: Identifiable, Codable {
    let id: UUID
    var fullName: String
    var licenseNumber: String
    var phoneNumber: String
    var email: String
    var address: String
    var status: DriverStatus
    var createdAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case licenseNumber = "license_number"
        case phoneNumber = "phone_number"
        case email
        case address
        case status
        case createdAt = "created_at"
    }
}

struct FMTrip: Identifiable, Codable {
    let id: UUID
    var vehicleId: UUID
    var vehicleName: String
    var startLocation: String
    var destination: String
    var distance: String
    var startDate: Date
    var startTime: Date
    var status: String = "Completed"
    
    enum CodingKeys: String, CodingKey {
        case id
        case vehicleId = "vehicle_id"
        case vehicleName = "vehicle_name"
        case startLocation = "start_location"
        case destination
        case distance
        case startDate = "start_date"
        case startTime = "start_time"
        case status
    }
}

struct FMActivity: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var timestamp: Date
    var icon: String
    var color: String // Hex or name
}

// MARK: - Form Data Models

struct VehicleCreationData {
    var registrationNumber: String = ""
    var vehicleType: VehicleType = .lightCommercial
    var manufacturer: String = ""
    var model: String = ""
    var fuelType: FuelType = .diesel
    var capacity: String = ""
    var registrationDate: Date = Date()
    var status: VehicleStatus = .active
    var assignedDriverId: UUID?
}

struct DriverCreationData {
    var fullName: String = ""
    var licenseNumber: String = ""
    var phoneNumber: String = ""
    var email: String = ""
    var address: String = ""
    var status: DriverStatus = .available
}


struct TripCreationData {
    var vehicleId: UUID?
    var startLocation: String = ""
    var destination: String = ""
    var distance: String = ""
    var startDate: Date = Date()
    var startTime: Date = Date()
}
