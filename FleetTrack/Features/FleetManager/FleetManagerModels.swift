//
//  FleetManagerModels.swift
//  FleetTrack
//
//  Created for Fleet Manager specific requirements
//  Updated to match database schema
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

struct MaintenanceLog: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var serviceTypes: [String]
    var description: String
}

// MARK: - FM Models (Match DB Schema)

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
    var vin: String?
    var mileage: Double?
    var insuranceStatus: String?
    var lastService: Date?
    var nextServiceDue: Date?
    var maintenanceServices: [String]?
    var maintenanceDescription: String?
    var maintenanceLogs: [MaintenanceLog]?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case registrationNumber = "registration_number"
        case vehicleType = "vehicle_type"
        case manufacturer
        case model
        case fuelType = "fuel_type"
        case capacity
        case registrationDate = "registration_date"
        case status
        case assignedDriverId = "assigned_driver_id"
        case assignedDriverName = "assigned_driver_name"
        case vin
        case mileage
        case insuranceStatus = "insurance_status"
        case lastService = "last_service"
        case nextServiceDue = "next_service_due"
        case maintenanceServices = "maintenance_services"
        case maintenanceDescription = "maintenance_description"
        case maintenanceLogs = "maintenance_logs"
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        registrationNumber: String,
        vehicleType: VehicleType,
        manufacturer: String,
        model: String,
        fuelType: FuelType = .diesel,
        capacity: String,
        registrationDate: Date = Date(),
        status: VehicleStatus = .active,
        assignedDriverId: UUID? = nil,
        assignedDriverName: String? = nil,
        vin: String? = nil,
        mileage: Double? = nil,
        insuranceStatus: String? = nil,
        lastService: Date? = nil,
        nextServiceDue: Date? = nil,
        maintenanceServices: [String]? = nil,
        maintenanceDescription: String? = nil,
        maintenanceLogs: [MaintenanceLog]? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.registrationNumber = registrationNumber
        self.vehicleType = vehicleType
        self.manufacturer = manufacturer
        self.model = model
        self.fuelType = fuelType
        self.capacity = capacity
        self.registrationDate = registrationDate
        self.status = status
        self.assignedDriverId = assignedDriverId
        self.assignedDriverName = assignedDriverName
        self.vin = vin
        self.mileage = mileage
        self.insuranceStatus = insuranceStatus
        self.lastService = lastService
        self.nextServiceDue = nextServiceDue
        self.maintenanceServices = maintenanceServices
        self.maintenanceDescription = maintenanceDescription
        self.maintenanceLogs = maintenanceLogs
        self.createdAt = createdAt
    }
}

struct FMDriver: Identifiable, Codable {
    let id: UUID
    var userId: UUID?
    var fullName: String?  // Made optional to handle NULL in database
    var licenseNumber: String?
    var driverLicenseNumber: String?
    var phoneNumber: String?
    var email: String?
    var address: String?
    var status: DriverStatus?  // Made optional for incomplete records
    var isActive: Bool?  // Made optional for incomplete records
    var createdAt: Date?  // Made optional for incomplete records
    var updatedAt: Date?  // Made optional for incomplete records
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fullName = "full_name"
        case licenseNumber = "license_number"
        case driverLicenseNumber = "driver_license_number"
        case phoneNumber = "phone_number"
        case email
        case address
        case status
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        fullName: String? = nil,
        licenseNumber: String? = nil,
        driverLicenseNumber: String? = nil,
        phoneNumber: String? = nil,
        email: String? = nil,
        address: String? = nil,
        status: DriverStatus? = .available,
        isActive: Bool? = true,
        createdAt: Date? = Date(),
        updatedAt: Date? = Date()
    ) {
        self.id = id
        self.userId = userId
        self.fullName = fullName
        self.licenseNumber = licenseNumber
        self.driverLicenseNumber = driverLicenseNumber
        self.phoneNumber = phoneNumber
        self.email = email
        self.address = address
        self.status = status
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Convenience computed property for display
    var displayName: String {
        fullName ?? email ?? "Unknown Driver"
    }
}

struct FMTrip: Identifiable, Codable {
    let id: UUID
    var vehicleId: UUID
    var driverId: UUID
    var status: String
    var startAddress: String?
    var endAddress: String?
    var distance: Double?
    var startTime: Date?
    var purpose: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vehicleId = "vehicle_id"
        case driverId = "driver_id"
        case status
        case startAddress = "start_address"
        case endAddress = "end_address"
        case distance
        case startTime = "start_time"
        case purpose
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        vehicleId: UUID,
        driverId: UUID,
        status: String = "Scheduled",
        startAddress: String? = nil,
        endAddress: String? = nil,
        distance: Double? = nil,
        startTime: Date? = nil,
        purpose: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.vehicleId = vehicleId
        self.driverId = driverId
        self.status = status
        self.startAddress = startAddress
        self.endAddress = endAddress
        self.distance = distance
        self.startTime = startTime
        self.purpose = purpose
        self.createdAt = createdAt
    }
    
    // Convenience computed properties for display
    var vehicleName: String {
        return "" // Will be populated from join or separate fetch
    }
    
    var formattedDistance: String {
        guard let dist = distance else { return "N/A" }
        return String(format: "%.1f km", dist)
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
    var vehicleType: VehicleType = .truck
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
    var driverId: UUID?
    var startAddress: String = ""
    var endAddress: String = ""
    var startLatitude: Double?
    var startLongitude: Double?
    var endLatitude: Double?
    var endLongitude: Double?
    var distance: Double?
    var startTime: Date = Date()
    var purpose: String = ""
}
struct MaintenanceStaffCreationData {
    var fullName: String = ""
    var specialization: String = ""
    var phoneNumber: String = ""
    var email: String = ""
    var employeeId: String = ""
    var yearsOfExperience: String = ""
}

struct FMMaintenanceStaff: Identifiable, Codable {
    let id: UUID
    var userId: UUID?
    var fullName: String?
    var email: String?
    var phoneNumber: String?
    var specialization: String?
    var yearsOfExperience: Int?
    var status: String?
    var isActive: Bool?
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fullName = "full_name"
        case email
        case phoneNumber = "phone_number"
        case specialization
        case yearsOfExperience = "years_of_experience"
        case status
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
