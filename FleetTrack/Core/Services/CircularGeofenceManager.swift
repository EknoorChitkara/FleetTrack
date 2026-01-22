import Foundation
import CoreLocation
import UserNotifications
import Supabase
import Combine

class CircularGeofenceManager: NSObject, ObservableObject {
    static let shared = CircularGeofenceManager()
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    
    // In-memory store of active geofences to map IDs back to names
    @Published var activeGeofences: [CircularGeofence] = []
    
    // Hard limit by iOS
    private let MAX_MONITORED_REGIONS = 20
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        // CRITICAL: Request Always Authorization for background geofencing
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        // Precise location helps with small geofences
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // MARK: - App Persistence & Fetching
    
    func fetchAndMonitorGeofences() async {
        do {
            // Need a custom decoder if using JSON string dates, but "geofences" table is standard
            let zones: [CircularGeofence] = try await supabase.database
                .from("geofences")
                .select()
                .execute()
                .value
            
            print("🌍 Fetched \(zones.count) geofences from Supabase")
            
            await MainActor.run {
                // Stop old ones first to ensure clean state
                stopAllMonitoring()
                
                // Monitor only active geofences (capped at 20)
                let activeZones = zones.filter { $0.isActive }
                for zone in activeZones.prefix(MAX_MONITORED_REGIONS) {
                    startMonitoring(geofence: zone)
                }
                
                // Store all geofences (both active and inactive) for UI display
                activeGeofences = zones
            }
            
        } catch {
            print("❌ Failed to fetch geofences: \(error)")
        }
    }
    
    // MARK: - Public API
    
    func saveGeofence(_ geofence: CircularGeofence) async throws {
        // 1. Save to Supabase
        try await supabase.database
            .from("geofences")
            .insert(geofence)
            .execute()
        
        print("☁️ Saved new geofence to Supabase: \(geofence.name)")
        
        // 2. Start monitoring immediately if active
        await MainActor.run {
            if geofence.isActive {
                startMonitoring(geofence: geofence)
            }
            // Add to local array regardless of active status
            if !activeGeofences.contains(where: { $0.id == geofence.id }) {
                activeGeofences.append(geofence)
            }
        }
    }
    
    func updateGeofence(_ geofence: CircularGeofence) async throws {
        // 1. Update in Supabase
        try await supabase.database
            .from("geofences")
            .update(geofence)
            .eq("id", value: geofence.id.uuidString)
            .execute()
        
        print("☁️ Updated geofence in Supabase: \(geofence.name)")
        
        // 2. Restart monitoring with new parameters if active
        await MainActor.run {
            stopMonitoring(geofenceId: geofence.id)
            if geofence.isActive {
                startMonitoring(geofence: geofence)
            }
            // Update in local array and trigger UI update
            if let index = activeGeofences.firstIndex(where: { $0.id == geofence.id }) {
                print("📝 Updating geofence at index \(index): \(geofence.name) - isActive: \(geofence.isActive)")
                activeGeofences[index] = geofence
                // Force UI update
                objectWillChange.send()
            }
            print("📊 Total geofences in array: \(activeGeofences.count)")
        }
    }
    
    func deleteGeofence(_ geofenceId: UUID) async throws {
        // 1. Stop monitoring first
        await MainActor.run {
            stopMonitoring(geofenceId: geofenceId)
        }
        
        // 2. Delete from Supabase
        try await supabase.database
            .from("geofences")
            .delete()
            .eq("id", value: geofenceId.uuidString)
            .execute()
        
        print("☁️ Deleted geofence from Supabase: \(geofenceId)")
        
        // 3. Remove from local array
        await MainActor.run {
            activeGeofences.removeAll { $0.id == geofenceId }
        }
    }
    
    func toggleGeofenceStatus(_ geofenceId: UUID) async throws {
        guard let geofence = activeGeofences.first(where: { $0.id == geofenceId }) else {
            print("❌ Geofence not found: \(geofenceId)")
            return
        }
        
        // Create updated geofence with toggled status
        let updatedGeofence = CircularGeofence(
            id: geofence.id,
            name: geofence.name,
            latitude: geofence.latitude,
            longitude: geofence.longitude,
            radiusMeters: geofence.radiusMeters,
            notifyOnEntry: geofence.notifyOnEntry,
            notifyOnExit: geofence.notifyOnExit,
            isActive: !geofence.isActive
        )
        
        // Update in database and monitoring
        try await updateGeofence(updatedGeofence)
        
        print("✅ Toggled geofence status: \(geofence.name) is now \(updatedGeofence.isActive ? "active" : "paused")")
    }
    
    func startMonitoring(geofence: CircularGeofence) {
        // Validation: Check iOS limits
        if locationManager.monitoredRegions.count >= MAX_MONITORED_REGIONS {
            print("❌ Cannot monitor geofence '\(geofence.name)': Region limit reached.")
            return
        }
        
        let center = CLLocationCoordinate2D(
            latitude: geofence.latitude,
            longitude: geofence.longitude
        )
        
        // Define Region
        // Constrain radius to iOS max (typically ~200km is max, but explicit clamping is good)
        let clampedRadius = min(max(geofence.radiusMeters, 100), 100000)
        
        let region = CLCircularRegion(
            center: center,
            radius: clampedRadius,
            identifier: geofence.id.uuidString
        )
        
        region.notifyOnEntry = geofence.notifyOnEntry
        region.notifyOnExit = geofence.notifyOnExit
        
        // Register
        locationManager.startMonitoring(for: region)
        
        // Track locally if not already present
        // (Geofences stay in array even when paused, so check before adding)
        if !activeGeofences.contains(where: { $0.id == geofence.id }) {
            activeGeofences.append(geofence)
        }
        
        print("✅ Started monitoring circular geofence: \(geofence.name)")
    }
    
    func stopMonitoring(geofenceId: UUID) {
        let region = locationManager.monitoredRegions.first { $0.identifier == geofenceId.uuidString }
        
        if let region = region {
            locationManager.stopMonitoring(for: region)
            print("🛑 Stopped monitoring geofence: \(geofenceId)")
        }
        
        // Note: We don't remove from activeGeofences array here
        // That array is used for UI display of ALL geofences (active + paused)
        // Only delete operations should remove from the array
    }
    
    func stopAllMonitoring() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        // Note: activeGeofences array is NOT cleared here
        // It's used for UI display and should only be cleared when fetching fresh data
        print("🛑 Stopped all circular geofencing.")
    }
    
    // MARK: - Backend & Alerts
    
    private func handleEvent(regionId: String, type: GeofenceEventType) {
        guard let uuid = UUID(uuidString: regionId) else { return }
        
        // Find geofence metadata
        let name = activeGeofences.first(where: { $0.id == uuid })?.name ?? "Unknown Zone"
        
        print("📍 Geofence Event: \(type.rawValue) - \(name)")
        
        // 1. Local Notification
        sendLocalNotification(title: "Zone Alert", body: "Vehicle \(type == .enter ? "entered" : "exited") \(name)")
        
        // 2. Record to Backend
        Task {
            await recordEvent(geofenceId: uuid, type: type)
        }
    }
    
    private func recordEvent(geofenceId: UUID, type: GeofenceEventType) async {
        // TODO: Get actual vehicle/driver ID from Auth or Session
        let dummyVehicleId = UUID() 
        let geofenceName = activeGeofences.first(where: { $0.id == geofenceId })?.name ?? "Unknown Zone"
        
        // 1. Log Event
        let event = GeofenceEvent(
            geofenceId: geofenceId,
            vehicleId: dummyVehicleId, 
            eventType: type
        )
        
        // 2. Create Alert for Dashboard
        let alert = GeofenceAlert(
            tripId: UUID(), // Placeholder, or link to active trip if available
            title: "Zone \(type == .enter ? "Entry" : "Exit")",
            message: "Vehicle has \(type == .enter ? "entered" : "left") \(geofenceName)",
            type: "zone_\(type.rawValue.lowercased())"
        )
        
        do {
            // Save Event
            try await supabase.database
                .from("geofence_events")
                .insert(event)
                .execute()
            
            // Save Alert
            try await supabase.database
                .from("alerts")
                .insert(alert)
                .execute()
                
            print("☁️ Synced geofence event and alert to Supabase")
        } catch {
            print("⚠️ Failed to sync geofence data: \(error)")
        }
    }
    
    private func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - CLLocationManagerDelegate

extension CircularGeofenceManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleEvent(regionId: region.identifier, type: .enter)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
         if region is CLCircularRegion {
            handleEvent(regionId: region.identifier, type: .exit)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Circular Geofencing Error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
         print("❌ Monitoring failed for region \(region?.identifier ?? "?"): \(error.localizedDescription)")
    }
}
