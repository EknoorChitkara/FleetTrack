//
//  TripService.swift
//  FleetTrack
//
//  Service for managing trips - create, update, fetch trips
//

import Foundation
import Supabase

class TripService {
    static let shared = TripService()
    
    private init() {}
    
    // MARK: - Fetch Trips
    
    /// Fetch all trips for a specific driver
    func fetchDriverTrips(driverId: UUID) async throws -> [Trip] {
        let trips: [Trip] = try await supabase
            .from("trips")
            .select()
            .eq("driver_id", value: driverId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return trips
    }
    
    /// Fetch all trips (for Fleet Manager)
    func fetchAllTrips() async throws -> [Trip] {
        let trips: [Trip] = try await supabase
            .from("trips")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return trips
    }
    
    /// Fetch trips by status
    func fetchTrips(status: TripStatus) async throws -> [Trip] {
        let trips: [Trip] = try await supabase
            .from("trips")
            .select()
            .eq("status", value: status.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return trips
    }
    
    // MARK: - Create Trip
    
    /// Create a new trip assignment
    func createTrip(_ data: TripCreateData) async throws -> Trip {
        let newTrip = Trip(
            vehicleId: data.vehicleId,
            driverId: data.driverId,
            status: .scheduled,
            startLat: data.startLatitude,
            startLong: data.startLongitude,
            startAddress: data.startAddress,
            endLat: data.endLatitude,
            endLong: data.endLongitude,
            endAddress: data.endAddress,
            startTime: data.scheduledStartTime,
            distance: data.estimatedDistance,
            purpose: data.purpose,
            notes: data.notes,
            createdBy: data.createdBy
        )
        
        let trip: Trip = try await supabase
            .from("trips")
            .insert(newTrip)
            .select()
            .single()
            .execute()
            .value
        
        print("✅ Trip created: \(trip.id)")
        return trip
    }
    
    // MARK: - Update Trip Status
    
    /// Start a trip with required fuel/odometer data
    func startTrip(
        tripId: UUID,
        startOdometer: Double? = nil,
        startFuelLevel: Double? = nil,
        odometerPhotoUrl: String? = nil,
        gaugePhotoUrl: String? = nil,
        routeIndex: Int? = nil
    ) async throws {
        var updateData: [String: AnyJSON] = [
            "status": .string(TripStatus.ongoing.rawValue),
            "start_time": .string(ISO8601DateFormatter().string(from: Date())),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        if let odo = startOdometer { updateData["start_odometer"] = .double(odo) }
        if let fuel = startFuelLevel { updateData["start_fuel_level"] = .double(fuel) }
        if let odoUrl = odometerPhotoUrl { updateData["start_odometer_photo_url"] = .string(odoUrl) }
        if let fuelUrl = gaugePhotoUrl { updateData["start_fuel_gauge_photo_url"] = .string(fuelUrl) }
        
        if let index = routeIndex {
            updateData["actual_route_index"] = .integer(index)
        }
        
        try await supabase
            .from("trips")
            .update(updateData)
            .eq("id", value: tripId)
            .execute()
        
        print("✅ Trip \(tripId) started")
    }
    
    /// Complete a trip with required fuel/odometer data
    func completeTrip(
        tripId: UUID,
        endOdometer: Double? = nil,
        endFuelLevel: Double? = nil,
        odometerPhotoUrl: String? = nil,
        gaugePhotoUrl: String? = nil,
        actualDistance: Double? = nil
    ) async throws {
        var updateData: [String: AnyJSON] = [
            "status": .string(TripStatus.completed.rawValue),
            "end_time": .string(ISO8601DateFormatter().string(from: Date())),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        if let odo = endOdometer { updateData["end_odometer"] = .double(odo) }
        if let fuel = endFuelLevel { updateData["end_fuel_level"] = .double(fuel) }
        if let odoUrl = odometerPhotoUrl { updateData["end_odometer_photo_url"] = .string(odoUrl) }
        if let fuelUrl = gaugePhotoUrl { updateData["end_fuel_gauge_photo_url"] = .string(fuelUrl) }
        
        if let distance = actualDistance {
            updateData["distance"] = .double(distance)
        }
        
        try await supabase
            .from("trips")
            .update(updateData)
            .eq("id", value: tripId)
            .execute()
        
        print("✅ Trip \(tripId) completed")
    }
    
    /// Cancel a trip
    func cancelTrip(tripId: UUID, reason: String? = nil) async throws {
        var updateData: [String: AnyJSON] = [
            "status": .string(TripStatus.cancelled.rawValue),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        
        if let reason = reason {
            updateData["notes"] = .string(reason)
        }
        
        try await supabase
            .from("trips")
            .update(updateData)
            .eq("id", value: tripId)
            .execute()
        
        print("✅ Trip \(tripId) cancelled")
    }
    
    // MARK: - Photo Uploads
    
    /// Upload a photo to Supabase Storage
    /// - Returns: Public URL of the uploaded image
    func uploadTripPhoto(data: Data, path: String) async throws -> String {
        let bucketName = SupabaseConfig.tripPhotosBucket
        let fileOptions = FileOptions(cacheControl: "3600", contentType: "image/jpeg")
        
        // 1. Upload data
        try await supabase.storage
            .from(bucketName)
            .upload(path, data: data, options: fileOptions)
            
        // 2. Get Public URL
        return try supabase.storage
            .from(bucketName)
            .getPublicURL(path: path)
            .absoluteString
    }
}

// MARK: - Trip Create Data

struct TripCreateData: Codable {
    let vehicleId: UUID
    let driverId: UUID
    let startAddress: String
    let startLatitude: Double?
    let startLongitude: Double?
    let endAddress: String
    let endLatitude: Double?
    let endLongitude: Double?
    let scheduledStartTime: Date?
    let estimatedDistance: Double?
    let purpose: String?
    let notes: String?
    let createdBy: UUID?
    
    enum CodingKeys: String, CodingKey {
        case vehicleId = "vehicle_id"
        case driverId = "driver_id"
        case startAddress = "start_address"
        case startLatitude = "start_latitude"
        case startLongitude = "start_longitude"
        case endAddress = "end_address"
        case endLatitude = "end_latitude"
        case endLongitude = "end_longitude"
        case scheduledStartTime = "scheduled_start_time"
        case estimatedDistance = "estimated_distance"
        case purpose
        case notes
        case createdBy = "created_by"
    }
    
    init(
        vehicleId: UUID,
        driverId: UUID,
        startAddress: String,
        startLatitude: Double? = nil,
        startLongitude: Double? = nil,
        endAddress: String,
        endLatitude: Double? = nil,
        endLongitude: Double? = nil,
        scheduledStartTime: Date? = nil,
        estimatedDistance: Double? = nil,
        purpose: String? = nil,
        notes: String? = nil,
        createdBy: UUID? = nil
    ) {
        self.vehicleId = vehicleId
        self.driverId = driverId
        self.startAddress = startAddress
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.endAddress = endAddress
        self.endLatitude = endLatitude
        self.endLongitude = endLongitude
        self.scheduledStartTime = scheduledStartTime
        self.estimatedDistance = estimatedDistance
        self.purpose = purpose
        self.notes = notes
        self.createdBy = createdBy
    }
}
