//
//  VehicleInspectionViewModel.swift
//  FleetTrack
//
//  Created for Driver
//

import Foundation
import Combine
import SwiftUI

@MainActor
class VehicleInspectionViewModel: ObservableObject {
    @Published var assignedVehicle: Vehicle?
    @Published var checklists: [InspectionItem] = []
    @Published var maintenanceHistory: [MaintenanceRecord] = []
    @Published var selectedServiceType: MaintenanceType = .scheduledService
    @Published var serviceDate = Date()
    @Published var serviceNotes = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Mock user/driver for context (in real app, fetched from session)
    private var userId: UUID
    
    init(userId: UUID) {
        self.userId = userId
        // Initialize with default items
        self.checklists = VehicleInspection.defaultChecklistItems
    }
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        // Simulating data fetching
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000) // 1 second delay
        
        // Mock data loading
        self.assignedVehicle = Vehicle.mockVehicle1
        self.maintenanceHistory = MaintenanceRecord.mockRecords.sorted(by: { $0.scheduledDate > $1.scheduledDate })
    }
    
    func toggleItemStatus(id: UUID) {
        if let index = checklists.firstIndex(where: { $0.id == id }) {
            // Simple toggle for now: Pass <-> Fail (or initially Pass)
            // Ideally could be a 3-state toggle if needed, or separate buttons
            // Here we assume checking the box means "Checked/Pass"
            // If we want detailed Pass/Fail, we might need UI for that.
            // Based on the screenshot, it looks like a simple checkbox for "Done".
            // Let's assume the checkbox means "Pass".
            // If unchecked, it might be pending.
            
            // However, the screenshot shows circles. Let's assume tap toggles "Pass".
            // Additional tap could go back to pending?
            
            checklists[index].status = checklists[index].status == .pass ? .fail : .pass
        }
    }
    
    func submitInspection() async {
        isLoading = true
        defer { isLoading = false } // Ensuring isLoading is reset even if we return early
        
        guard let vehicle = assignedVehicle else { return }
        
        print("📝 Submitting inspection for vehicle \(vehicle.registrationNumber)")
        print("📋 Checklist Items:")
        for item in checklists {
            print("- \(item.name): \(item.status.rawValue)")
        }
        
        // Simulate network call
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        print("✅ Inspection submitted successfully!")
        
        // Reset checklist for next time?
        // checklists = VehicleInspection.defaultChecklistItems
    }
    
    func requestService() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let vehicle = assignedVehicle else { return }
        
        print("🔧 Requesting service for vehicle \(vehicle.registrationNumber)")
        print("Type: \(selectedServiceType.rawValue)")
        print("Date: \(serviceDate)")
        print("Notes: \(serviceNotes)")
        
        // Create a mock record locally and add to history to show immediate feedback
        let newRecord = MaintenanceRecord(
            vehicleId: vehicle.id,
            type: selectedServiceType,
            status: .scheduled,
            title: selectedServiceType.rawValue,
            description: serviceNotes,
            scheduledDate: serviceDate,
            createdAt: Date()
        )
        
        withAnimation {
            maintenanceHistory.insert(newRecord, at: 0)
        }
        
        // Simulate network call
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        print("✅ Service request submitted successfully!")
        
        // Reset form
        serviceNotes = ""
        serviceDate = Date()
    }
}
