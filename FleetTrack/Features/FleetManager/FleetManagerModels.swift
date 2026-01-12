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
