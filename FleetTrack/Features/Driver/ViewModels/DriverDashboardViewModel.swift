//
//  DriverDashboardViewModel.swift
//  FleetTrack
//
//  Created by FleetTrack on 09/01/26.
//

import Foundation
import Combine

@MainActor
final class DriverDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var driver: Driver?
    @Published var assignedVehicle: Vehicle?
    @Published var recentTrips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let driverService = DriverService.shared
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    func loadDashboardData(user: User) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Fetch Driver Profile
            let driverProfile = try await driverService.getDriverProfile(userId: user.id)
            self.driver = driverProfile
            
            // 2. Fetch Assigned Vehicle if available
            if let vehicleId = driverProfile.currentVehicleId {
                self.assignedVehicle = try await driverService.getAssignedVehicle(vehicleId: vehicleId)
            } else {
                self.assignedVehicle = nil
            }
            
            // 3. Fetch Recent Trips
            self.recentTrips = try await driverService.getRecentTrips(driverId: driverProfile.id)
            
            isLoading = false
        } catch {
            print("❌ Error loading driver dashboard: \(error)")
            
            // Check for PGRST116: No rows found (Driver record missing)
            if "\(error)".contains("PGRST116") {
                print("ℹ️ Driver profile not found. Displaying empty dashboard.")
                // Initialize an empty driver object so the UI can show 0/nil values
                self.driver = Driver(
                    userId: user.id,
                    driverLicenseNumber: "Not Set",
                    licenseType: .lightMotorVehicle,
                    licenseExpiryDate: Date()
                )
                self.assignedVehicle = nil
                self.recentTrips = []
                self.errorMessage = nil // Clear error to show empty UI
            } else {
                self.errorMessage = "Failed to load dashboard data. Please try again."
            }
            
            self.isLoading = false
        }
    }
}
