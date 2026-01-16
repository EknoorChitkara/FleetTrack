//
//  RemoteLocationProvider.swift
//  FleetTrack
//
//  Created for Fleet Manager Trip Map Integration
//

import Foundation
import CoreLocation
import Combine
import Supabase

/// Location provider that subscribes to remote vehicle updates via Supabase
/// Used by Fleet Managers to track vehicles
@MainActor
class RemoteLocationProvider: TripLocationProvider {
    @Published var currentLocation: Location?
    @Published var heading: Double?
    @Published var status: LocationProviderStatus = .offline
    @Published var isUpdating: Bool = false
    
    private let vehicleId: UUID
    private var realtimeTask: Task<Void, Never>?
    
    // Configurable staleness threshold (e.g., 5 minutes)
    private let staleThreshold: TimeInterval = 300
    private var stalenessTimer: Timer?
    
    init(vehicleId: UUID, initialLocation: Location? = nil) {
        self.vehicleId = vehicleId
        self.currentLocation = initialLocation
        
        // Check initial staleness
        if let loc = initialLocation {
            checkStaleness(timestamp: loc.timestamp)
        }
    }
    
    func startTracking() {
        guard !isUpdating else { return }
        
        status = .connecting
        isUpdating = true
        
        setupRealtimeSubscription()
        startStalenessTimer()
    }
    
    func stopTracking() {
        isUpdating = false
        status = .offline
        
        realtimeTask?.cancel()
        realtimeTask = nil
        
        stalenessTimer?.invalidate()
        stalenessTimer = nil
    }
    
    private func setupRealtimeSubscription() {
        let channelName = "vehicle_tracking_\(vehicleId.uuidString)"
        
        realtimeTask = Task {
            let channel = await supabase.channel(channelName)
            
            // Subscribe to UPDATE events on the vehicles table for this specific vehicle
            let insertStream = await channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "vehicles",
                filter: "id=eq.\(vehicleId.uuidString)"
            )
            
            let updateStream = await channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "vehicles",
                filter: "id=eq.\(vehicleId.uuidString)"
            )
            
            await channel.subscribe()
            
            // Listen for updates
            for await change in updateStream {
                handleUpdate(record: change.record)
            }
        }
    }
    
    private func handleUpdate(record: [String: AnyJSON]) {
        // Extract location fields
        guard case let .double(lat) = record["latitude"],
              case let .double(long) = record["longitude"] else {
            return
        }
        
        // Extract timestamp (default to now if missing)
        let timestamp: Date
        if case let .string(timeStr) = record["last_location_update"] {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            timestamp = formatter.date(from: timeStr) ?? Date()
        } else {
            timestamp = Date()
        }
        
        // Extract address if available
        let address: String
        if case let .string(addr) = record["address"] {
            address = addr
        } else {
            address = "Updated Location"
        }
        
        self.currentLocation = Location(
            latitude: lat,
            longitude: long,
            address: address,
            timestamp: timestamp
        )
        
        self.checkStaleness(timestamp: timestamp)
    }
    
    private func startStalenessTimer() {
        stalenessTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self, let lastLoc = self.currentLocation else { return }
            Task { @MainActor in
                self.checkStaleness(timestamp: lastLoc.timestamp)
            }
        }
    }
    
    private func checkStaleness(timestamp: Date) {
        let timeSinceUpdate = Date().timeIntervalSince(timestamp)
        
        if timeSinceUpdate > staleThreshold {
            status = .stale(since: timestamp)
        } else {
            status = .active
        }
    }
    
    deinit {
        stopTracking()
    }
}
