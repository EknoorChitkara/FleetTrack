//
//  VehicleInspectionViewModel.swift
//  FleetTrack
//
//  Created for Driver App
//

import Foundation
import SwiftUI
import Combine

@MainActor
class VehicleInspectionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var selectedTab: InspectionTab = .summary
    @Published var checklistItems: [InspectionItem] = []
    @Published var historyRecords: [InspectionHistoryRecord] = []
    @Published var vehicle: Vehicle?
    
    // Booking Form
    @Published var selectedServiceType: ServiceType = .routineMaintenance
    @Published var preferredDate: Date = Date()
    @Published var notes: String = ""
    
    // Alert State
    @Published var showingConfirmation: Bool = false
    @Published var confirmationMessage: String = ""
    
    // MARK: - Initialization
    
    init(vehicle: Vehicle?) {
        self.vehicle = vehicle
        self.checklistItems = InspectionItem.defaultChecklist
        self.historyRecords = []
    }
    
    // MARK: - Actions
    
    func submitInspection() {
        // Simulate network call
        print("Submitting inspection for \(vehicle?.registrationNumber ?? "Unknown")")
        print("Items checked: \(checklistItems.filter { $0.isChecked }.count)/\(checklistItems.count)")
        
        // Show success
        confirmationMessage = "Inspection submitted successfully!"
        showingConfirmation = true
        
        // Reset checklist?
        // checklistItems = InspectionItem.defaultChecklist // Optional
    }
    
    func submitServiceRequest() {
        let request = ServiceRequest(
            serviceType: selectedServiceType,
            preferredDate: preferredDate,
            notes: notes
        )
        
        print("Submitting service request: \(request)")
        
        // Show success
        confirmationMessage = "Service request for \(selectedServiceType.rawValue) submitted!"
        showingConfirmation = true
        
        // Reset form
        notes = ""
        selectedServiceType = .routineMaintenance
    }
    
    func markItemAsChecked(_ id: UUID) {
        if let index = checklistItems.firstIndex(where: { $0.id == id }) {
            checklistItems[index].isChecked.toggle()
        }
    }
}
