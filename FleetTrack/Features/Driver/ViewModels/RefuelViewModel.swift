//
//  RefuelViewModel.swift
//  FleetTrack
//
//  Created for managing refueling operations
//

import Foundation
import SwiftUI
import Combine
import Supabase

@MainActor
class RefuelViewModel: ObservableObject {
    // Form Data
    @Published var litersAdded: String = ""
    @Published var totalCost: String = ""
    @Published var odometerReading: String = ""
    @Published var receiptImage: UIImage?
    @Published var gaugeImage: UIImage?
    
    // UI State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    
    private let tripId: UUID
    private let vehicleId: UUID
    private let driverId: UUID
    
    // Dependencies
    private let trackingService = FuelTrackingService.shared
    private let tripService = TripService.shared
    
    init(tripId: UUID, vehicleId: UUID, driverId: UUID) {
        self.tripId = tripId
        self.vehicleId = vehicleId
        self.driverId = driverId
    }
    
    var isValid: Bool {
        !litersAdded.isEmpty && 
        Double(litersAdded) != nil &&
        receiptImage != nil &&
        gaugeImage != nil
    }
    
    func submitRefill() async {
        guard let liters = Double(litersAdded) else {
            errorMessage = "Invalid fuel amount"
            return
        }
        
        let cost = Double(totalCost)
        let odometer = Double(odometerReading)
        
        isLoading = true
        errorMessage = nil
        
        do {
            guard let session = try? await SupabaseClientManager.shared.client.auth.session else {
                errorMessage = "Please log in again to submit the refill."
                isLoading = false
                return
            }
            let authUserId = session.user.id
            // 1. Upload Photos
            var receiptUrl: String?
            var gaugeUrl: String?
            
            if let receiptData = receiptImage?.jpegData(compressionQuality: 0.7) {
                let path = "refills/\(tripId)/receipt_\(Date().timeIntervalSince1970).jpg"
                receiptUrl = try await tripService.uploadTripPhoto(data: receiptData, path: path)
            }
            
            if let gaugeData = gaugeImage?.jpegData(compressionQuality: 0.7) {
                let path = "refills/\(tripId)/gauge_\(Date().timeIntervalSince1970).jpg"
                gaugeUrl = try await tripService.uploadTripPhoto(data: gaugeData, path: path)
            }
            
            // 2. Log Refill
            _ = try await trackingService.addRefill(
                tripId: tripId,
                vehicleId: vehicleId,
                driverId: authUserId,
                liters: liters,
                cost: cost,
                odometer: odometer,
                receiptUrl: receiptUrl,
                gaugeUrl: gaugeUrl,
                location: nil // TODO: Add location logic if needed
            )
            
            isSuccess = true
            
        } catch {
            print("❌ Refill failed: \(error)")
            errorMessage = "Failed to submit refill. Please try again."
        }
        
        isLoading = false
    }
}
