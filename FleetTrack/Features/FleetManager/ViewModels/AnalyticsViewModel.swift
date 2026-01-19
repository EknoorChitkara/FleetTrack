//
//  AnalyticsViewModel.swift
//  FleetTrack
//
//  Created for Fleet Manager Analytics
//

import Foundation
import SwiftUI
import Combine
import Supabase

// MARK: - Analytics Models

struct MonthlyAnalytics: Identifiable {
    let id = UUID()
    let date: Date
    let fuelCost: Double
    let maintenanceCost: Double
    let totalDistance: Double
    
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    var totalCost: Double {
        fuelCost + maintenanceCost
    }
}

struct VehicleCostBreakdown: Identifiable {
    let id = UUID()
    let vehicleType: String
    let cost: Double
    let color: Color
}

// MARK: - View Model

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var monthlyData: [MonthlyAnalytics] = []
    @Published var vehicleCostData: [VehicleCostBreakdown] = []
    @Published var totalFleetCost: Double = 0
    @Published var totalDistance: Double = 0
    @Published var fleetEfficiency: Double = 0 // km per Liter
    @Published var isLoading = false
    
    // Config
    private let fuelRate: Double = 96.0 // INR per Liter
    
    init() {
        // Load data on init
        Task {
            await loadAnalytics()
        }
    }
    
    func loadAnalytics() async {
        await MainActor.run { isLoading = true }
        
        do {
            // 1. Fetch Raw Data
            async let tripsTask: [Trip] = SupabaseClientManager.shared.client.database
                .from("trips")
                .select()
                .eq("status", value: "Completed") // Only completed trips
                .execute()
                .value
            
            async let maintenanceTask: [MaintenanceTask] = SupabaseClientManager.shared.client.database
                .from("maintenance_tasks") // Check table name
                .select()
                .eq("status", value: "Completed")
                .execute()
                .value
                
            async let vehiclesTask: [Vehicle] = SupabaseClientManager.shared.client.database
                .from("vehicles")
                .select()
                .execute()
                .value
            
            let (trips, maintenance, vehicles) = try await (tripsTask, maintenanceTask, vehiclesTask)
            
            // 2. Process Data
            let processedData = processAnalytics(trips: trips, maintenance: maintenance, vehicles: vehicles)
            
            await MainActor.run {
                self.monthlyData = processedData.monthly
                self.vehicleCostData = processedData.breakdown
                self.totalFleetCost = processedData.totalCost
                self.totalDistance = processedData.totalDistance
                self.fleetEfficiency = processedData.efficiency
                self.isLoading = false
            }
            
        } catch {
            print("Analytics Fetch Error: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
    
    // MARK: - processing Logic
    
    private func processAnalytics(trips: [Trip], maintenance: [MaintenanceTask], vehicles: [Vehicle]) -> (monthly: [MonthlyAnalytics], breakdown: [VehicleCostBreakdown], totalCost: Double, totalDistance: Double, efficiency: Double) {
        
        let calendar = Calendar.current
        var monthlyDataDict: [Date: (fuel: Double, maint: Double, dist: Double, fuelLiters: Double)] = [:]
        var typeCostDict: [String: Double] = [:]
        
        // Helper to get start of month
        func startOfMonth(for date: Date) -> Date {
            let components = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: components) ?? date
        }
        
        let vehicleMap = Dictionary(uniqueKeysWithValues: vehicles.map { ($0.id, $0) })
        
        // 1. Process Trips (Fuel Cost & Distance)
        for trip in trips {
            let month = startOfMonth(for: trip.endTime ?? trip.createdAt)
            let distance = trip.distance ?? 0.0
            
            // Calculate Fuel
            // Logic: Use Manual Logs if available, else Estimate based on Vehicle Type
            var fuelConsumed = 0.0
            
            if let startF = trip.startFuelLevel, let endF = trip.endFuelLevel, let vehicle = vehicleMap[trip.vehicleId], let capacity = vehicle.tankCapacity {
                // Calculation: (Start% - End%) * Capacity
                // Note: If Refueled during trip, this logic is simple. ideally we need Refuel Logs.
                // For now, we fall back to estimation if this is negative or zero, or just use estimation for consistency.
                let consumedPercent = max(0, (startF - endF) / 100.0)
                fuelConsumed = consumedPercent * capacity
            }
            
            // Fallback to estimation based on type if (manual logs missing OR result is weirdly low for valid distance)
            // Estimation: Truck=4kpl, Van=8kpl, Car=12kpl, Other=6kpl
            if fuelConsumed == 0 && distance > 0 {
                let vehicle = vehicleMap[trip.vehicleId]
                let type = vehicle?.vehicleType ?? .other
                let efficiency: Double
                switch type {
                case .truck: efficiency = 4.0
                case .van: efficiency = 8.0
                case .car: efficiency = 12.0
                case .other: efficiency = 6.0
                }
                fuelConsumed = distance / efficiency
            }
            
            let fuelCost = fuelConsumed * fuelRate
            
            // Accumulate Monthly
            var current = monthlyDataDict[month] ?? (0,0,0,0)
            current.fuel += fuelCost
            current.dist += distance
            current.fuelLiters += fuelConsumed
            monthlyDataDict[month] = current
            
            // Accumulate Type Breakdown
            let type = vehicleMap[trip.vehicleId]?.vehicleType.rawValue ?? "Unknown"
            typeCostDict[type, default: 0] += fuelCost
        }
        
        // 2. Process Maintenance (Cost)
        for task in maintenance {
            let month = startOfMonth(for: task.completedDate ?? task.updatedAt)
            
            // Accumulate Monthly
            var current = monthlyDataDict[month] ?? (0,0,0,0)
            current.maint += task.totalCost
            monthlyDataDict[month] = current
            
            // Accumulate Type Breakdown
            // Need to find vehicle type for this task. MaintenanceTask has vehicleRegistrationNumber but not ID always directly usable in map if we only fetched vehicles.
            // But we can try to math reg number.
            if let vehicle = vehicles.first(where: { $0.registrationNumber == task.vehicleRegistrationNumber }) {
                let type = vehicle.vehicleType.rawValue
                typeCostDict[type, default: 0] += task.totalCost
            } else {
                typeCostDict["Other", default: 0] += task.totalCost
            }
        }
        
        // 3. Convert to Output Models
        let monthlyAnalytics = monthlyDataDict.map { (date, values) in
            MonthlyAnalytics(
                date: date,
                fuelCost: values.fuel,
                maintenanceCost: values.maint,
                totalDistance: values.dist
            )
        }.sorted(by: { $0.date < $1.date })
        
        // Fill in missing months? Optional, but good for charts. (Skipping for brevity, charts handle gaps usually)
        
        let typeColors: [String: Color] = [
            "Truck": .purple,
            "Van": .blue,
            "Car": .orange,
            "Other": .gray
        ]
        
        let breakdown = typeCostDict.map { (type, cost) in
            VehicleCostBreakdown(
                vehicleType: type,
                cost: cost,
                color: typeColors[type] ?? .gray
            )
        }.sorted(by: { $0.cost > $1.cost })
        
        let totalCost = monthlyAnalytics.reduce(0) { $0 + $1.totalCost }
        let totalDist = monthlyAnalytics.reduce(0) { $0 + $1.totalDistance }
        let totalFuel = monthlyDataDict.values.reduce(0) { $0 + $1.fuelLiters }
        
        let efficiency = totalFuel > 0 ? (totalDist / totalFuel) : 0.0
        
        return (monthlyAnalytics, breakdown, totalCost, totalDist, efficiency)
    }
}
