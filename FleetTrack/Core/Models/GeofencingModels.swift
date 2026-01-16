//import Foundation
//import CoreLocation
//
//struct GeofenceRoute: Codable, Identifiable {
//    let routeId: UUID
//    let startLatitude: Double
//    let startLongitude: Double
//    let endLatitude: Double
//    let endLongitude: Double
//    /// Polyline points encoded as a string (algorithm to be determined, e.g. Google Polyline Algorithm)
//    /// or a JSON string representation of coordinates.
//    let encodedPolyline: String
//    let corridorRadiusMeters: Double
//    
//    var id: UUID { routeId }
//    
//    // Helper to get start coordinate
//    var startCoordinate: CLLocationCoordinate2D {
//        CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
//    }
//    
//    // Helper to get end coordinate
//    var endCoordinate: CLLocationCoordinate2D {
//        CLLocationCoordinate2D(latitude: endLatitude, longitude: endLongitude)
//    }
//}
//
//struct GeofenceViolation: Codable, Identifiable {
//    let id: UUID
//    let routeId: UUID
//    let driverLatitude: Double
//    let driverLongitude: Double
//    let distanceFromRoute: Double
//    let timestamp: Date
//    
//    init(routeId: UUID, driverLatitude: Double, driverLongitude: Double, distanceFromRoute: Double, timestamp: Date = Date()) {
//        self.id = UUID()
//        self.routeId = routeId
//        self.driverLatitude = driverLatitude
//        self.driverLongitude = driverLongitude
//        self.distanceFromRoute = distanceFromRoute
//        self.timestamp = timestamp
//    }
//    
//    var driverLocation: CLLocationCoordinate2D {
//        CLLocationCoordinate2D(latitude: driverLatitude, longitude: driverLongitude)
//    }
//}
//
//struct GeofenceAlert: Codable, Identifiable {
//    let id: UUID
//    let tripId: UUID
//    let title: String
//    let message: String
//    let type: String // "geofence_violation"
//    let timestamp: Date
//    let isRead: Bool
//    
//    init(tripId: UUID, title: String, message: String, type: String = "geofence_violation", timestamp: Date = Date()) {
//        self.id = UUID()
//        self.tripId = tripId
//        self.title = title
//        self.message = message
//        self.type = type
//        self.timestamp = timestamp
//        self.isRead = false
//    }
//}
//
//// MARK: - Circular Geofencing Models (Stationary Zones)
//
//struct CircularGeofence: Codable, Identifiable {
//    let id: UUID
//    let name: String
//    let latitude: Double
//    let longitude: Double
//    let radiusMeters: Double
//    let notifyOnEntry: Bool
//    let notifyOnExit: Bool
//    
//    var coordinate: CLLocationCoordinate2D {
//        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//    }
//}
//
//enum GeofenceEventType: String, Codable {
//    case enter = "ENTER"
//    case exit = "EXIT"
//}
//
//struct GeofenceEvent: Codable, Identifiable {
//    let id: UUID
//    let geofenceId: UUID
//    let vehicleId: UUID // or DriverID
//    let eventType: GeofenceEventType
//    let timestamp: Date
//    
//    init(geofenceId: UUID, vehicleId: UUID, eventType: GeofenceEventType, timestamp: Date = Date()) {
//        self.id = UUID()
//        self.geofenceId = geofenceId
//        self.vehicleId = vehicleId
//        self.eventType = eventType
//        self.timestamp = timestamp
//    }
//}
