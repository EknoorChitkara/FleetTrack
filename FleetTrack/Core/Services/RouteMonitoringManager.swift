//import Foundation
//import CoreLocation
//import MapKit
//import Combine
//import Supabase
//
//class RouteMonitoringManager: NSObject, ObservableObject {
//    static let shared = RouteMonitoringManager()
//    
//    // MARK: - Published State
//    @Published var currentViolation: GeofenceViolation?
//    @Published var isOffRoute: Bool = false
//    @Published var currentDistanceFromRoute: Double = 0.0
//    
//    // MARK: - Private Properties
//    private let locationManager = CLLocationManager()
//    private var activeRoute: GeofenceRoute?
//    private var routePoints: [MKMapPoint] = []
//    
//    // Violation Cooldown
//    private var lastViolationTimestamp: Date?
//    private let violationCooldown: TimeInterval = 300 // 5 minutes (Step 6)
//    
//    // MARK: - Initialization
//    private override init() {
//        super.init()
//        setupLocationManager()
//    }
//    
//    // MARK: - Setup
//    // Step 4: Setup Location Tracking
//    private func setupLocationManager() {
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.distanceFilter = 30 // 30 meters
//        locationManager.allowsBackgroundLocationUpdates = true
//        locationManager.pausesLocationUpdatesAutomatically = false
//        locationManager.activityType = .automotiveNavigation
//    }
//    
//    // MARK: - Public API
//    
//    func startMonitoring(route: GeofenceRoute) {
//        self.activeRoute = route
//        self.routePoints = decodePolyline(route.encodedPolyline)
//        self.isOffRoute = false
//        self.currentViolation = nil
//        self.lastViolationTimestamp = nil
//        
//        locationManager.startUpdatingLocation()
//        
//        // Step 7: Create Geofence Route in Backend
//        Task {
//            do {
//                try await saveGeofenceRoute(route)
//            } catch {
//                print("Failed to save geofence route: \(error)")
//            }
//        }
//        
//        print("📍 Started route monitoring for Route ID: \(route.routeId)")
//    }
//    
//    func stopMonitoring() {
//        locationManager.stopUpdatingLocation()
//        activeRoute = nil
//        routePoints = []
//        isOffRoute = false
//        print("📍 Stopped route monitoring")
//    }
//    
//    // MARK: - Helpers
//    
//    private func decodePolyline(_ encoded: String) -> [MKMapPoint] {
//         guard let data = encoded.data(using: .utf8),
//              let coordinates = try? JSONDecoder().decode([[Double]].self, from: data) else {
//            return []
//        }
//        return coordinates.map { MKMapPoint(CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1])) }
//    }
//    
//    // MARK: - Backend Integration (Step 7)
//    
//    private func saveGeofenceRoute(_ route: GeofenceRoute) async throws {
//        // Assuming table 'geofence_routes'
//        try await supabase.database
//            .from("geofence_routes")
//            .insert(route)
//            .execute()
//    }
//    
//    private func recordViolation(_ violation: GeofenceViolation) async {
//        do {
//            try await supabase.database
//                .from("geofence_violations")
//                .insert(violation)
//                .execute()
//            print("⚠️ Recorded violation for Route ID: \(violation.routeId)")
//            
//            // Trigger Alert for Fleet Manager
//            let alert = GeofenceAlert(
//                tripId: violation.routeId, // Assuming routeId == tripId
//                title: "Geofence Violation",
//                message: "Driver has deviated \(Int(violation.distanceFromRoute))m from the route."
//            )
//            await recordAlert(alert)
//            
//        } catch {
//            print("Failed to record violation: \(error)")
//        }
//    }
//    
//    private func recordAlert(_ alert: GeofenceAlert) async {
//         do {
//             try await supabase.database
//                 .from("alerts")
//                 .insert(alert)
//                 .execute()
//             print("🔔 Alert sent to Fleet Manager")
//         } catch {
//             print("Failed to send alert: \(error)")
//         }
//    }
//    
//    // MARK: - Logic
//    
//    // Step 3: Geometry Distance Calculation
//    private func calculateMinDistance(from location: CLLocationCoordinate2D) -> Double {
//        let driverPoint = MKMapPoint(location)
//        guard routePoints.count > 1 else { return 0 }
//        
//        var minDistance: Double = .greatestFiniteMagnitude
//        
//        // Iterate over segments
//        for i in 0..<routePoints.count - 1 {
//            let p1 = routePoints[i]
//            let p2 = routePoints[i+1]
//            let distance = distanceToSegment(p: driverPoint, a: p1, b: p2)
//            if distance < minDistance {
//                minDistance = distance
//            }
//        }
//        return minDistance
//    }
//    
//    private func distanceToSegment(p: MKMapPoint, a: MKMapPoint, b: MKMapPoint) -> Double {
//        let x = p.x; let y = p.y
//        let x1 = a.x; let y1 = a.y
//        let x2 = b.x; let y2 = b.y
//        
//        let A = x - x1
//        let B = y - y1
//        let C = x2 - x1
//        let D = y2 - y1
//        
//        let dot = A * C + B * D
//        let len_sq = C * C + D * D
//        var param = -1.0
//        
//        if len_sq != 0 {
//            param = dot / len_sq
//        }
//        
//        var xx, yy: Double
//        
//        if param < 0 {
//            xx = x1; yy = y1
//        } else if param > 1 {
//            xx = x2; yy = y2
//        } else {
//            xx = x1 + param * C
//            yy = y1 + param * D
//        }
//        
//        let projectedPoint = MKMapPoint(x: xx, y: yy)
//        return MKMetersBetweenMapPoints(p, projectedPoint)
//    }
//}
//
//// MARK: - CLLocationManagerDelegate
//extension RouteMonitoringManager: CLLocationManagerDelegate {
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.last else { return }
//        
//        // Filter by accuracy (Step 4: Ignore updates where horizontalAccuracy > 50 meters)
//        // Note: Using 50 as the upper bound of the 30-50 range suggested
//        if location.horizontalAccuracy < 0 || location.horizontalAccuracy > 50 {
//            return
//        }
//        
//        guard let route = activeRoute else { return }
//        
//        // Step 5: Route Corridor Check Loop
//        let distance = calculateMinDistance(from: location.coordinate)
//        
//        // Update published state on MainActor
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            self.currentDistanceFromRoute = distance
//            
//            if distance > route.corridorRadiusMeters {
//                // Outside corridor
//                if !self.isOffRoute {
//                     self.isOffRoute = true
//                }
//                self.handleViolation(at: location, distance: distance, routeId: route.routeId)
//            } else {
//                // Inside corridor
//                if self.isOffRoute {
//                    self.isOffRoute = false
//                }
//            }
//        }
//    }
//    
//    private func handleViolation(at location: CLLocation, distance: Double, routeId: UUID) {
//        let now = Date()
//        
//        // Step 6: Violation Cooldown Logic
//        if let lastTime = lastViolationTimestamp, now.timeIntervalSince(lastTime) < violationCooldown {
//            return // Ignore inside cooldown
//        }
//        
//        // Record violation
//        let violation = GeofenceViolation(
//            routeId: routeId,
//            driverLatitude: location.coordinate.latitude,
//            driverLongitude: location.coordinate.longitude,
//            distanceFromRoute: distance,
//            timestamp: now
//        )
//        
//        self.currentViolation = violation
//        self.lastViolationTimestamp = now
//        
//        // Step 7: Record to Backend
//        Task {
//            await recordViolation(violation)
//        }
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("❌ Route Monitoring Location Error: \(error.localizedDescription)")
//    }
//}
