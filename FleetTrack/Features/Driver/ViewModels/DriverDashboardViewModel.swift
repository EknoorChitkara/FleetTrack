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
    @Published var ongoingTrip: Trip?
    @Published var upcomingTrip: Trip?
    @Published var recentTrips: [Trip] = []
    @Published var completedTripsCount: Int = 0
    @Published var totalDistance: Double = 0.0
    @Published var completionRate: Double = 0.0
    @Published var avgSpeed: Double = 0.0
    @Published var avgTripDistance: Double = 0.0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var dashboardActions: [DashboardAction] = []
    @Published var needsOnboarding = false
    
    // MARK: - Dependencies
    
    private let driverService = DriverService.shared
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    func loadDashboardData(user: User) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let driverProfile = try await driverService.getDriverProfile(userId: user.id)
            self.driver = driverProfile
            
            // Trigger onboarding if record exists but is incomplete
            if driverProfile.driverLicenseNumber == nil || driverProfile.driverLicenseNumber == "Not Set" || driverProfile.driverLicenseNumber?.isEmpty == true {
                self.needsOnboarding = true
            } else {
                self.needsOnboarding = false
            }
            
            // 2. Fetch Assigned Vehicle (Query by Driver ID from Database)
            do {
                self.assignedVehicle = try await driverService.getAssignedVehicle(driverId: driverProfile.id)
                if let vehicle = self.assignedVehicle {
                    print("🚗 Assigned Vehicle: \(vehicle.manufacturer) \(vehicle.model) (\(vehicle.registrationNumber))")
                } else {
                    print("ℹ️ Driver has no vehicle assigned in 'vehicles' table.")
                    self.assignedVehicle = nil
                }
            } catch {
                print("❌ Failed to fetch assigned vehicle: \(error)")
                // Don't clear nil here, let it be nil
                self.assignedVehicle = nil
            }
            
            // 3. Fetch Ongoing Initial Trip (Prioritized)
            self.ongoingTrip = try await driverService.getOngoingTrip(driverId: driverProfile.id)
            
            // 4. Fetch Next Scheduled Trip (Upcoming) if no ongoing
            // (We can fetch both, but UI will prioritize ongoing)
            self.upcomingTrip = try await driverService.getNextScheduledTrip(driverId: driverProfile.id)
            
            // 5. Fetch Recent Trips
            self.recentTrips = try await driverService.getRecentTrips(driverId: driverProfile.id)
            
            // 4. Fetch Driver Stats (Count, Distance, Duration for Avg Speed/Avg Dist)
            let stats = try await driverService.getDriverStats(driverId: driverProfile.id)
            
            self.completedTripsCount = stats.tripCount
            self.totalDistance = stats.totalDistance
            
            // Stats Logic
            if stats.tripCount > 0 {
                self.avgTripDistance = stats.totalDistance / Double(stats.tripCount)
            } else {
                self.avgTripDistance = 0.0
            }
            
            if stats.totalDuration > 0 {
                let hours = stats.totalDuration / 3600.0
                self.avgSpeed = stats.totalDistance / hours
            } else {
                self.avgSpeed = 0.0
            }
            
            // For now, keep On-Time as is from profile, or default to 100%
            // self.completionRate = ... (Using existing onTimeDeliveryRate for now)
            
            // For now, keep On-Time as is from profile, or default to 100%
            // self.completionRate = ... (Using existing onTimeDeliveryRate for now)
            
            // 6. Load Dashboard Actions (Static for now, but data-driven via model)
            self.dashboardActions = DashboardAction.allActions
            
            isLoading = false
        } catch {
            print("❌ Error loading driver dashboard: \(error)")
            
            // Check for PGRST116: No rows found (Driver record missing)
            if "\(error)".contains("PGRST116") {
                print("ℹ️ Driver profile not found. Triggering onboarding.")
                self.needsOnboarding = true
                // Initialize an empty driver object so the UI can show 0/nil values
                self.driver = Driver(
                    userId: user.id,
                    fullName: user.name,
                    email: user.email,
                    phoneNumber: user.phoneNumber,
                    driverLicenseNumber: "Not Set",
                    licenseType: .lightMotorVehicle,
                    licenseExpiryDate: nil // Specifically set to nil as requested by handling
                )
                self.assignedVehicle = nil
                self.ongoingTrip = nil
                self.upcomingTrip = nil
                self.recentTrips = []
                self.completedTripsCount = 0
                self.totalDistance = 0.0
                self.avgSpeed = 0.0
                self.avgTripDistance = 0.0
                self.dashboardActions = DashboardAction.allActions
                self.errorMessage = nil // Clear error to show empty UI
            } else {
                self.errorMessage = "Failed to load dashboard data. Please try again."
            }
            
            self.isLoading = false
        }
    }
}
