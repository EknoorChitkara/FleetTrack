//
//  DriverTripsViewModel.swift
//  FleetTrack
//
//  Created for Driver
//

import Foundation
import Combine
import SwiftUI

@MainActor
class DriverTripsViewModel: ObservableObject {
    @Published var upcomingTrips: [Trip] = []
    @Published var historyTrips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // For Active Trip
    @Published var activeTrip: Trip?
    
    // For Voice Logging
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    private var timer: Timer?
    
    // Route Selection
    @Published var selectedRouteId: UUID?
    
    private var driverId: UUID
    
    init(driverId: UUID) {
        self.driverId = driverId
    }
    
    func loadTrips() async {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate network
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        // Mock Data
        // let mockTrips = Trip.mockTrips
        
        self.upcomingTrips = [] // mockTrips.filter { $0.status == .scheduled || $0.status == .ongoing }
        self.historyTrips = [] // mockTrips.filter { $0.status == .completed || $0.status == .cancelled }
        
        // Auto-select ongoing trip if any
        if let ongoing = upcomingTrips.first(where: { $0.status == .ongoing }) {
            self.activeTrip = ongoing
        }
    }
    
    func startTrip(_ trip: Trip) {
        // Logic to transition trip status to ongoing
        if let index = upcomingTrips.firstIndex(where: { $0.id == trip.id }) {
            var updatedTrip = trip
            updatedTrip.status = .ongoing
            // Set default route suggestion if none chosen
            if updatedTrip.routeSuggestions.isEmpty {
                // Populate suggestions on start for demo
                updatedTrip.routeSuggestions = [
                    RouteSuggestion(name: "Fastest", duration: 900, distance: 18, tag: .standard),
                    RouteSuggestion(name: "Fuel Saver", duration: 1320, distance: 16, tag: .low),
                    RouteSuggestion(name: "Balanced", duration: 1080, distance: 17, tag: .optimal, isRecommended: true)
                ]
            }
            upcomingTrips[index] = updatedTrip
            activeTrip = updatedTrip
        }
    }
    
    func completeTrip() {
        guard let trip = activeTrip else { return }
        
        // Logic to transition to completed
        var completedTrip = trip
        completedTrip.status = .completed
        completedTrip.endTime = Date()
        
        // Move to history locally
        if let index = upcomingTrips.firstIndex(where: { $0.id == trip.id }) {
            upcomingTrips.remove(at: index)
        }
        historyTrips.insert(completedTrip, at: 0)
        activeTrip = nil
    }
    
    // MARK: - Voice Recording Mock
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        recordingDuration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.recordingDuration += 1
        }
    }
    
    private func stopRecording() {
        isRecording = false
        timer?.invalidate()
        timer = nil
        
        // Save mock recording
        if let activeTrip = activeTrip {
            let log = VoiceLog(tripId: activeTrip.id, duration: recordingDuration)
            // Add to trip's voice logs (in a real app, this would be an API call)
            // For now, we just print
            print("🎙️ Voice Log saved: \(log.duration) seconds")
            
             // Locally update for UI check if needed, though we don't display the list in Active View yet
            if let index = upcomingTrips.firstIndex(where: { $0.id == activeTrip.id }) {
                var updatedTrip = upcomingTrips[index]
                updatedTrip.voiceLogs.append(log)
                upcomingTrips[index] = updatedTrip
                self.activeTrip = updatedTrip
            }
        }
    }
}
