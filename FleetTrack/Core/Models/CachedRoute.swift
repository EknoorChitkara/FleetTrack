//
//  CachedRoute.swift
//  FleetTrack
//
//  Offline First Architecture - Route Caching
//

import Foundation
import SwiftData
import CoreLocation

/// Stores route geometry for offline display
@Model
class CachedRoute {
    var tripId: UUID
    var polylineData: Data // Encoded array of coordinates
    var steps: [String]
    var totalDistance: Double
    var estimatedTime: TimeInterval
    var cachedAt: Date
    
    init(
        tripId: UUID,
        polylineData: Data,
        steps: [String],
        totalDistance: Double,
        estimatedTime: TimeInterval,
        cachedAt: Date = Date()
    ) {
        self.tripId = tripId
        self.polylineData = polylineData
        self.steps = steps
        self.totalDistance = totalDistance
        self.estimatedTime = estimatedTime
        self.cachedAt = cachedAt
    }
    
    // MARK: - Coordinate Encoding/Decoding
    
    /// Encode CLLocationCoordinate2D array to Data
    static func encodeCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> Data {
        let latLongs = coordinates.map { [$0.latitude, $0.longitude] }
        return (try? JSONEncoder().encode(latLongs)) ?? Data()
    }
    
    /// Decode Data back to CLLocationCoordinate2D array
    func decodeCoordinates() -> [CLLocationCoordinate2D] {
        guard let latLongs = try? JSONDecoder().decode([[Double]].self, from: polylineData) else {
            return []
        }
        return latLongs.compactMap { arr in
            guard arr.count == 2 else { return nil }
            return CLLocationCoordinate2D(latitude: arr[0], longitude: arr[1])
        }
    }
}
