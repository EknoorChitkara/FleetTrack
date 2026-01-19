//
//  OfflineTripAction.swift
//  FleetTrack
//
//  Offline First Architecture - Pending Actions Queue
//

import Foundation
import SwiftData

/// Represents a trip action that was performed offline and needs to sync
@Model
class OfflineTripAction {
    var id: UUID
    var tripId: UUID
    var actionType: String // "start", "complete", "location_update", "cancel"
    var payload: Data // JSON encoded action details
    var createdAt: Date
    var synced: Bool
    var syncAttempts: Int
    var lastSyncError: String?
    
    init(
        id: UUID = UUID(),
        tripId: UUID,
        actionType: String,
        payload: Data,
        createdAt: Date = Date(),
        synced: Bool = false,
        syncAttempts: Int = 0,
        lastSyncError: String? = nil
    ) {
        self.id = id
        self.tripId = tripId
        self.actionType = actionType
        self.payload = payload
        self.createdAt = createdAt
        self.synced = synced
        self.syncAttempts = syncAttempts
        self.lastSyncError = lastSyncError
    }
}

// MARK: - Action Payloads

struct TripStartPayload: Codable {
    let tripId: UUID
    let startedAt: Date
    let startLatitude: Double?
    let startLongitude: Double?
}

struct TripCompletePayload: Codable {
    let tripId: UUID
    let completedAt: Date
    let endLatitude: Double?
    let endLongitude: Double?
    let actualDistance: Double?
}

struct LocationUpdatePayload: Codable {
    let tripId: UUID
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let speed: Double?
    let heading: Double?
}
