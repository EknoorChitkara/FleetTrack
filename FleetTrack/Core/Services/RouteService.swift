import Foundation
import MapKit
import CoreLocation

enum RouteServiceError: Error {
    case noRouteFound
    case encodingFailed
}

class RouteService {
    static let shared = RouteService()
    
    private init() {}
    
    /// Fetches a route between two coordinates using MapKit
    func fetchRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        guard let route = response.routes.first else {
            throw RouteServiceError.noRouteFound
        }
        
        return route
    }
    
    /// Creates a GeofenceRoute model from an MKRoute
    /// Encodes the polyline as a JSON string of coordinates [[lat, lon], ...]
    //    func createGeofenceRoute(
    //        from route: MKRoute,
    //        routeId: UUID,
    //        start: CLLocationCoordinate2D,
    //        end: CLLocationCoordinate2D,
    //        corridorRadius: Double
    //    ) throws -> GeofenceRoute {
    //        let polyline = route.polyline
    //        let pointCount = polyline.pointCount
    //        let points = polyline.points()
    //        
    //        var coordinates: [[Double]] = []
    //        coordinates.reserveCapacity(pointCount)
    //        
    //        for i in 0..<pointCount {
    //            let coordinate = points[i].coordinate
    //            coordinates.append([coordinate.latitude, coordinate.longitude])
    //        }
    //        
    //        guard let jsonData = try? JSONSerialization.data(withJSONObject: coordinates),
    //              let encodedString = String(data: jsonData, encoding: .utf8) else {
    //            throw RouteServiceError.encodingFailed
    //        }
    //        
    //        return GeofenceRoute(
    //            routeId: routeId,
    //            startLatitude: start.latitude,
    //            startLongitude: start.longitude,
    //            endLatitude: end.latitude,
    //            endLongitude: end.longitude,
    //            encodedPolyline: encodedString,
    //            corridorRadiusMeters: corridorRadius
    //        )
    //    }
    //}
}
