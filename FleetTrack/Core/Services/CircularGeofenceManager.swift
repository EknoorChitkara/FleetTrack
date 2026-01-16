//import Foundation
//import CoreLocation
//import UserNotifications
//import Supabase
//
//class CircularGeofenceManager: NSObject, ObservableObject {
//    static let shared = CircularGeofenceManager()
//    
//    // MARK: - Properties
//    private let locationManager = CLLocationManager()
//    
//    // In-memory store of active geofences to map IDs back to names
//    @Published var activeGeofences: [CircularGeofence] = []
//    
//    // Hard limit by iOS
//    private let MAX_MONITORED_REGIONS = 20
//    
//    // MARK: - Initialization
//    override init() {
//        super.init()
//        setupLocationManager()
//    }
//    
//    private func setupLocationManager() {
//        locationManager.delegate = self
//        // CRITICAL: Request Always Authorization for background geofencing
//        locationManager.requestAlwaysAuthorization()
//        locationManager.allowsBackgroundLocationUpdates = true
//        // Precise location helps with small geofences
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//    }
//    
//    // MARK: - Public API
//    
//    func startMonitoring(geofence: CircularGeofence) {
//        // Validation: Check iOS limits
//        if locationManager.monitoredRegions.count >= MAX_MONITORED_REGIONS {
//            print("❌ Cannot monitor geofence '\(geofence.name)': Region limit reached.")
//            return
//        }
//        
//        let center = CLLocationCoordinate2D(
//            latitude: geofence.latitude,
//            longitude: geofence.longitude
//        )
//        
//        // Define Region
//        // Constrain radius to iOS max (typically ~200km is max, but explicit clamping is good)
//        let clampedRadius = min(max(geofence.radiusMeters, 100), 100000)
//        
//        let region = CLCircularRegion(
//            center: center,
//            radius: clampedRadius,
//            identifier: geofence.id.uuidString
//        )
//        
//        region.notifyOnEntry = geofence.notifyOnEntry
//        region.notifyOnExit = geofence.notifyOnExit
//        
//        // Register
//        locationManager.startMonitoring(for: region)
//        
//        // Track locally
//        if !activeGeofences.contains(where: { $0.id == geofence.id }) {
//            activeGeofences.append(geofence)
//        }
//        
//        print("✅ Started monitoring circular geofence: \(geofence.name)")
//    }
//    
//    func stopMonitoring(geofenceId: UUID) {
//        let region = locationManager.monitoredRegions.first { $0.identifier == geofenceId.uuidString }
//        
//        if let region = region {
//            locationManager.stopMonitoring(for: region)
//            print("🛑 Stopped monitoring geofence: \(geofenceId)")
//        }
//        
//        activeGeofences.removeAll { $0.id == geofenceId }
//    }
//    
//    func stopAllMonitoring() {
//        for region in locationManager.monitoredRegions {
//            locationManager.stopMonitoring(for: region)
//        }
//        activeGeofences.removeAll()
//        print("🛑 Stopped all circular geofencing.")
//    }
//    
//    // MARK: - Backend & Alerts
//    
//    private func handleEvent(regionId: String, type: GeofenceEventType) {
//        guard let uuid = UUID(uuidString: regionId) else { return }
//        
//        // Find geofence metadata
//        let name = activeGeofences.first(where: { $0.id == uuid })?.name ?? "Unknown Zone"
//        
//        print("📍 Geofence Event: \(type.rawValue) - \(name)")
//        
//        // 1. Local Notification
//        sendLocalNotification(title: "Zone Alert", body: "Vehicle \(type == .enter ? "entered" : "exited") \(name)")
//        
//        // 2. Record to Backend
//        Task {
//            await recordEvent(geofenceId: uuid, type: type)
//        }
//    }
//    
//    private func recordEvent(geofenceId: UUID, type: GeofenceEventType) async {
//        // TODO: Get actual vehicle/driver ID from Auth or Session
//        let dummyVehicleId = UUID() 
//        
//        let event = GeofenceEvent(
//            geofenceId: geofenceId,
//            vehicleId: dummyVehicleId, 
//            eventType: type
//        )
//        
//        do {
//            try await supabase.database
//                .from("geofence_events")
//                .insert(event)
//                .execute()
//            print("☁️ Synced geofence event to Supabase")
//        } catch {
//            print("⚠️ Failed to sync geofence event: \(error)")
//        }
//    }
//    
//    private func sendLocalNotification(title: String, body: String) {
//        let content = UNMutableNotificationContent()
//        content.title = title
//        content.body = body
//        content.sound = .default
//        
//        let request = UNNotificationRequest(
//            identifier: UUID().uuidString,
//            content: content,
//            trigger: nil
//        )
//        
//        UNUserNotificationCenter.current().add(request)
//    }
//}
//
//// MARK: - CLLocationManagerDelegate
//
//extension CircularGeofenceManager: CLLocationManagerDelegate {
//    
//    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
//        if region is CLCircularRegion {
//            handleEvent(regionId: region.identifier, type: .enter)
//        }
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
//         if region is CLCircularRegion {
//            handleEvent(regionId: region.identifier, type: .exit)
//        }
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("❌ Circular Geofencing Error: \(error.localizedDescription)")
//    }
//    
//    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
//         print("❌ Monitoring failed for region \(region?.identifier ?? "?"): \(error.localizedDescription)")
//    }
//}
