//
//  LiveActivityManager.swift
//  FleetTrack
//
//  Manages Live Activity lifecycle for Trip Tracking
//

import ActivityKit
import Foundation

@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var currentActivity: Activity<TripActivityAttributes>?
    @Published var isActivityActive: Bool = false
    
    private init() {}
    
    // MARK: - Start Live Activity
    
    /// Start a Live Activity when a trip begins
    func startLiveActivity(
        tripId: UUID,
        pickupAddress: String,
        destination: String,
        vehicleRegistration: String,
        driverName: String,
        initialEtaMinutes: Int,
        initialDistanceKm: Double
    ) {
        // Check if Live Activities are supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("❌ Live Activities are not enabled on this device")
            return
        }
        
        // End any existing activity first
        if currentActivity != nil {
            endLiveActivity()
        }
        
        let attributes = TripActivityAttributes(
            tripId: tripId.uuidString,
            pickupAddress: pickupAddress,
            vehicleRegistration: vehicleRegistration
        )
        
        let initialState = TripActivityAttributes.ContentState(
            destination: destination,
            etaMinutes: initialEtaMinutes,
            distanceKm: initialDistanceKm,
            status: "pickup",
            driverName: driverName
        )
        
        let content = ActivityContent(state: initialState, staleDate: nil)
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil // Use local updates, not push notifications
            )
            currentActivity = activity
            isActivityActive = true
            print("✅ Live Activity started for trip \(tripId)")
            HapticManager.shared.triggerSuccess()
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
    }
    
    // MARK: - Update Live Activity
    
    /// Update the Live Activity with new ETA and distance
    func updateLiveActivity(
        etaMinutes: Int,
        distanceKm: Double,
        status: String,
        destination: String,
        driverName: String
    ) async {
        guard let activity = currentActivity else {
            print("⚠️ No active Live Activity to update")
            return
        }
        
        let updatedState = TripActivityAttributes.ContentState(
            destination: destination,
            etaMinutes: etaMinutes,
            distanceKm: distanceKm,
            status: status,
            driverName: driverName
        )
        
        let updatedContent = ActivityContent(state: updatedState, staleDate: nil)
        
        await activity.update(updatedContent)
        print("📍 Live Activity updated: ETA \(etaMinutes)min, \(String(format: "%.1f", distanceKm))km")
    }
    
    /// Update status to "delivering" after pickup
    func updateToDelivering(
        destination: String,
        etaMinutes: Int,
        distanceKm: Double,
        driverName: String
    ) async {
        await updateLiveActivity(
            etaMinutes: etaMinutes,
            distanceKm: distanceKm,
            status: "delivering",
            destination: destination,
            driverName: driverName
        )
    }
    
    // MARK: - End Live Activity
    
    /// End the Live Activity when trip completes
    func endLiveActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            let finalState = TripActivityAttributes.ContentState(
                destination: "Trip Completed",
                etaMinutes: 0,
                distanceKm: 0,
                status: "completed",
                driverName: ""
            )
            
            let finalContent = ActivityContent(state: finalState, staleDate: nil)
            
            await activity.end(finalContent, dismissalPolicy: .after(.now + 60)) // Dismiss after 1 minute
            
            await MainActor.run {
                currentActivity = nil
                isActivityActive = false
            }
            
            print("✅ Live Activity ended")
            HapticManager.shared.triggerSuccess()
        }
    }
    
    // MARK: - Cancel Live Activity
    
    /// Cancel the Live Activity immediately (e.g., trip cancelled)
    func cancelLiveActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            
            await MainActor.run {
                currentActivity = nil
                isActivityActive = false
            }
            
            print("🛑 Live Activity cancelled")
        }
    }
}
