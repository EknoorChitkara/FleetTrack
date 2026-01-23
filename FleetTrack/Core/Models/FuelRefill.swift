//
//  FuelRefill.swift
//  FleetTrack
//
//  Created for tracking fuel refills during trips
//

import Foundation

struct FuelRefill: Identifiable, Codable, Hashable {
    let id: UUID
    var tripId: UUID
    var vehicleId: UUID
    var driverId: UUID?
    
    // Fuel Details
    var fuelAddedLiters: Double
    var fuelCost: Double?
    var odometerReading: Double?
    
    // Photos
    var fuelGaugePhotoUrl: String?
    var receiptPhotoUrl: String?
    
    // Location
    var locationLatitude: Double?
    var locationLongitude: Double?
    
    // Timestamps
    var timestamp: Date
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case tripId = "trip_id"
        case vehicleId = "vehicle_id"
        case driverId = "driver_id"
        case fuelAddedLiters = "fuel_added_liters"
        case fuelCost = "fuel_cost"
        case odometerReading = "odometer_reading"
        case fuelGaugePhotoUrl = "fuel_gauge_photo_url"
        case receiptPhotoUrl = "receipt_photo_url"
        case locationLatitude = "location_latitude"
        case locationLongitude = "location_longitude"
        case timestamp
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        tripId: UUID,
        vehicleId: UUID,
        driverId: UUID? = nil,
        fuelAddedLiters: Double,
        fuelCost: Double? = nil,
        odometerReading: Double? = nil,
        fuelGaugePhotoUrl: String? = nil,
        receiptPhotoUrl: String? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        timestamp: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.tripId = tripId
        self.vehicleId = vehicleId
        self.driverId = driverId
        self.fuelAddedLiters = fuelAddedLiters
        self.fuelCost = fuelCost
        self.odometerReading = odometerReading
        self.fuelGaugePhotoUrl = fuelGaugePhotoUrl
        self.receiptPhotoUrl = receiptPhotoUrl
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.timestamp = timestamp
        self.createdAt = createdAt
    }
}
