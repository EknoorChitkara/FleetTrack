//
//  OfflineSyncManager.swift
//  FleetTrack
//
//  Offline First Architecture - Network Monitoring & Sync
//

import Foundation
import Network
import SwiftData
import Combine

/// Monitors network connectivity and syncs pending offline actions
@MainActor
class OfflineSyncManager: ObservableObject {
    static let shared = OfflineSyncManager()
    
    @Published var isOnline: Bool = true
    @Published var isSyncing: Bool = false
    @Published var pendingActionsCount: Int = 0
    
    private var monitor: NWPathMonitor?
    private var monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var modelContext: ModelContext?
    
    private init() {
        startMonitoring()
    }
    
    // MARK: - Setup
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await refreshPendingCount()
        }
    }
    
    // MARK: - Network Monitoring
    
    private func startMonitoring() {
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let wasOffline = self?.isOnline == false
                self?.isOnline = path.status == .satisfied
                
                // Trigger sync when coming back online
                if wasOffline && self?.isOnline == true {
                    print("📶 Network restored - triggering sync")
                    await self?.syncPendingActions()
                }
            }
        }
        monitor?.start(queue: monitorQueue)
    }
    
    // MARK: - Queue Offline Actions
    
    /// Queue a trip action for later sync
    func queueAction(tripId: UUID, actionType: String, payload: Encodable) {
        guard let modelContext = modelContext else {
            print("❌ OfflineSyncManager not configured with ModelContext")
            return
        }
        
        guard let payloadData = try? JSONEncoder().encode(OfflineAnyEncodable(payload)) else {
            print("❌ Failed to encode action payload")
            return
        }
        
        let action = OfflineTripAction(
            tripId: tripId,
            actionType: actionType,
            payload: payloadData
        )
        
        modelContext.insert(action)
        try? modelContext.save()
        
        Task {
            await refreshPendingCount()
        }
        
        print("📥 Queued offline action: \(actionType) for trip \(tripId)")
        
        // Try to sync immediately if online
        if isOnline {
            Task {
                await syncPendingActions()
            }
        }
    }
    
    // MARK: - Sync Logic
    
    /// Sync all pending actions to Supabase
    func syncPendingActions() async {
        guard let modelContext = modelContext else { return }
        guard !isSyncing else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let descriptor = FetchDescriptor<OfflineTripAction>(
            predicate: #Predicate { $0.synced == false },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        do {
            let pendingActions = try modelContext.fetch(descriptor)
            
            for action in pendingActions {
                do {
                    try await syncAction(action)
                    action.synced = true
                    print("✅ Synced action: \(action.actionType)")
                } catch {
                    action.syncAttempts += 1
                    action.lastSyncError = error.localizedDescription
                    print("❌ Failed to sync action: \(error)")
                }
            }
            
            try modelContext.save()
            await refreshPendingCount()
            
        } catch {
            print("❌ Failed to fetch pending actions: \(error)")
        }
    }
    
    private func syncAction(_ action: OfflineTripAction) async throws {
        let tripService = TripService.shared
        
        switch action.actionType {
        case "start":
            if let payload = try? JSONDecoder().decode(TripStartPayload.self, from: action.payload) {
                try await tripService.startTrip(tripId: payload.tripId)
            }
        case "complete":
            if let payload = try? JSONDecoder().decode(TripCompletePayload.self, from: action.payload) {
                try await tripService.completeTrip(tripId: payload.tripId)
            }
        case "location_update":
            // Location updates are batched differently, skip for now
            break
        default:
            print("⚠️ Unknown action type: \(action.actionType)")
        }
    }
    
    private func refreshPendingCount() async {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<OfflineTripAction>(
            predicate: #Predicate { $0.synced == false }
        )
        
        pendingActionsCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    // MARK: - Cleanup
    
    func cleanupSyncedActions() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<OfflineTripAction>(
            predicate: #Predicate { $0.synced == true }
        )
        
        do {
            let syncedActions = try modelContext.fetch(descriptor)
            for action in syncedActions {
                modelContext.delete(action)
            }
            try modelContext.save()
            print("🗑️ Cleaned up \(syncedActions.count) synced actions")
        } catch {
            print("❌ Failed to cleanup synced actions: \(error)")
        }
    }
}

// MARK: - Helper for encoding any Encodable

private struct OfflineAnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void
    
    init<T: Encodable>(_ wrapped: T) {
        encode = wrapped.encode
    }
    
    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
