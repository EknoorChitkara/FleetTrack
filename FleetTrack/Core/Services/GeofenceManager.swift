//
//  TripMonitoringManager.swift
//  FleetTrack
//
//  Monitors trip start/end locations using geofencing
//  Simplified: Uses existing Trip model (no separate geofences table)
//

import CoreLocation
import Combine
import UserNotifications

/// Trip monitoring event types
enum TripMonitoringEvent {
    case arrivedAtStart
    case arrivedAtDestination
    case leftStart
    case leftDestination
}

@MainActor
class TripMonitoringManager: NSObject, ObservableObject {
    static let shared = TripMonitoringManager()
    
    // iOS LIMIT: Maximum 20 monitored regions
    private let MAX_MONITORED_REGIONS = 20
    
    // Published properties
    @Published var monitoredTrips: [Trip] = []
    @Published var recentEvents: [(trip: Trip, event: TripMonitoringEvent, timestamp: Date)] = []
    
    // Private properties
    private let locationManager = CLLocationManager()
    private var tripRegionMap: [String: UUID] = [:] // region.identifier -> trip.id
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    // MARK: - Trip Monitoring
    
    /// Start monitoring a trip's start and end locations
    func startMonitoring(trip: Trip) {
        guard let startLat = trip.startLat,
              let startLong = trip.startLong,
              let endLat = trip.endLat,
              let endLong = trip.endLong else {
            print("⚠️ Trip \(trip.id) missing coordinates")
            return
        }
        
        // Check if we're at the limit
        if locationManager.monitoredRegions.count >= MAX_MONITORED_REGIONS {
            print("⚠️ Already monitoring 20 regions. Stop some before adding more.")
            return
        }
        
        // Create start region
        let startRegion = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: startLat, longitude: startLong),
            radius: 100, // 100 meters
            identifier: "trip-\(trip.id)-start"
        )
        startRegion.notifyOnEntry = true
        startRegion.notifyOnExit = true
        
        // Create end region
        let endRegion = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: endLat, longitude: endLong),
            radius: 100, // 100 meters
            identifier: "trip-\(trip.id)-end"
        )
        endRegion.notifyOnEntry = true
        endRegion.notifyOnExit = true
        
        // Start monitoring
        locationManager.startMonitoring(for: startRegion)
        locationManager.startMonitoring(for: endRegion)
        
        // Track trip
        if !monitoredTrips.contains(where: { $0.id == trip.id }) {
            monitoredTrips.append(trip)
        }
        
        // Map regions to trip
        tripRegionMap[startRegion.identifier] = trip.id
        tripRegionMap[endRegion.identifier] = trip.id
        
        print("📍 Started monitoring trip: \(trip.id)")
        print("   Start: \(trip.startAddress ?? "Unknown")")
        print("   End: \(trip.endAddress ?? "Unknown")")
    }
    
    /// Stop monitoring a specific trip
    func stopMonitoring(trip: Trip) {
        let startIdentifier = "trip-\(trip.id)-start"
        let endIdentifier = "trip-\(trip.id)-end"
        
        // Find and stop regions
        locationManager.monitoredRegions.forEach { region in
            if region.identifier == startIdentifier || region.identifier == endIdentifier {
                locationManager.stopMonitoring(for: region)
            }
        }
        
        // Remove from tracked trips
        monitoredTrips.removeAll { $0.id == trip.id }
        
        // Remove from map
        tripRegionMap.removeValue(forKey: startIdentifier)
        tripRegionMap.removeValue(forKey: endIdentifier)
        
        print("📍 Stopped monitoring trip: \(trip.id)")
    }
    
    /// Stop monitoring all trips
    func stopAllMonitoring() {
        locationManager.monitoredRegions.forEach { region in
            locationManager.stopMonitoring(for: region)
        }
        
        monitoredTrips.removeAll()
        tripRegionMap.removeAll()
        
        print("📍 Stopped monitoring all trips")
    }
    
    // MARK: - Event Handling
    
    private func handleRegionEntry(region: CLRegion) {
        guard let tripId = tripRegionMap[region.identifier],
              let trip = monitoredTrips.first(where: { $0.id == tripId }) else {
            return
        }
        
        let isStart = region.identifier.hasSuffix("-start")
        let event: TripMonitoringEvent = isStart ? .arrivedAtStart : .arrivedAtDestination
        let locationName = isStart ? (trip.startAddress ?? "Start") : (trip.endAddress ?? "Destination")
        
        print("✅ Arrived at \(locationName)")
        
        // Record event
        recentEvents.insert((trip: trip, event: event, timestamp: Date()), at: 0)
        
        // Keep only last 50 events
        if recentEvents.count > 50 {
            recentEvents = Array(recentEvents.prefix(50))
        }
        
        // Send notification
        sendNotification(
            title: isStart ? "Arrived at Pickup" : "Arrived at Destination",
            body: "You've arrived at \(locationName)"
        )
        
        // TODO: Update trip status in Supabase
        // If arrived at start -> status = .ongoing
        // If arrived at end -> status = .completed
    }
    
    private func handleRegionExit(region: CLRegion) {
        guard let tripId = tripRegionMap[region.identifier],
              let trip = monitoredTrips.first(where: { $0.id == tripId }) else {
            return
        }
        
        let isStart = region.identifier.hasSuffix("-start")
        let event: TripMonitoringEvent = isStart ? .leftStart : .leftDestination
        let locationName = isStart ? (trip.startAddress ?? "Start") : (trip.endAddress ?? "Destination")
        
        print("🚪 Left \(locationName)")
        
        // Record event
        recentEvents.insert((trip: trip, event: event, timestamp: Date()), at: 0)
        
        // Keep only last 50 events
        if recentEvents.count > 50 {
            recentEvents = Array(recentEvents.prefix(50))
        }
        
        // Send notification
        sendNotification(
            title: isStart ? "Left Pickup Location" : "Left Destination",
            body: "You've left \(locationName)"
        )
    }
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension TripMonitoringManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            handleRegionEntry(region: region)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in
            handleRegionExit(region: region)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Task { @MainActor in
            print("❌ Monitoring failed for region: \(region?.identifier ?? "unknown")")
            print("   Error: \(error.localizedDescription)")
        }
    }
}
