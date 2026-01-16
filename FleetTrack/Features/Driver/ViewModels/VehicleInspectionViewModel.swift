//
//  VehicleInspectionViewModel.swift
//  FleetTrack
//
//  Created for Driver App
//

import Foundation
import SwiftUI
import Combine
import Supabase

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
        
        Task {
            await fetchHistory()
        }
    }
    
    // MARK: - Data Loading
    
    @MainActor
    func fetchHistory() async {
        guard let vehicle = vehicle else { return }
        
        do {
            let inspections: [VehicleInspection] = try await supabase
                .from("vehicle_inspections")
                .select()
                .eq("vehicle_id", value: vehicle.id)
                .order("inspection_date", ascending: false)
                .limit(20)
                .execute()
                .value
            
            self.historyRecords = inspections.map { inspection in
                InspectionHistoryRecord(
                    id: inspection.id,
                    title: "Daily Inspection",
                    date: inspection.inspectionDate,
                    status: inspection.status,
                    description: inspection.notes ?? "No notes provided"
                )
            }
        } catch {
            print("❌ Failed to fetch inspection history: \(error)")
        }
    }
    
    // MARK: - Actions
    
    func submitInspection() async {
        guard let vehicle = vehicle else {
            confirmationMessage = "No vehicle assigned"
            showingConfirmation = true
            return
        }
        
        // Get current driver ID from session
        guard let session = try? await supabase.auth.session else {
            confirmationMessage = "Session expired. Please log in again."
            showingConfirmation = true
            return
        }
        
        do {
            // Fetch driver ID
            let drivers: [FMDriver] = try await supabase
                .from("drivers")
                .select()
                .eq("user_id", value: session.user.id)
                .execute()
                .value
            
            guard let driver = drivers.first else {
                confirmationMessage = "Driver profile not found"
                showingConfirmation = true
                return
            }
            
            let itemsChecked = checklistItems.filter { $0.isChecked }.count
            let allPassed = itemsChecked == checklistItems.count
            
            let inspection = VehicleInspection(
                id: UUID(),
                vehicleId: vehicle.id,
                driverId: driver.id,
                inspectionDate: Date(),
                checklistItems: checklistItems,
                itemsChecked: itemsChecked,
                totalItems: checklistItems.count,
                allItemsPassed: allPassed,
                notes: nil,
                status: "Completed",
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Save to Supabase
            try await supabase
                .from("vehicle_inspections")
                .insert(inspection)
                .execute()
            
            print("✅ Inspection submitted successfully for \(vehicle.registrationNumber)")
            print("   Items checked: \(itemsChecked)/\(checklistItems.count)")
            
            confirmationMessage = "Inspection submitted successfully! (\(itemsChecked)/\(checklistItems.count) items checked)"
            showingConfirmation = true
            
        } catch {
            print("❌ Error submitting inspection: \(error)")
            confirmationMessage = "Failed to submit inspection. Please try again."
            showingConfirmation = true
        }
    }
    
    func submitServiceRequest() {
        Task {
            guard let vehicle = vehicle else {
                confirmationMessage = "No vehicle assigned"
                showingConfirmation = true
                return
            }
            
            guard let session = try? await supabase.auth.session else {
                confirmationMessage = "Session expired. Please log in again."
                showingConfirmation = true
                return
            }
            
            do {
                // Fetch driver ID
                let drivers: [FMDriver] = try await supabase
                    .from("drivers")
                    .select()
                    .eq("user_id", value: session.user.id)
                    .execute()
                    .value
                
                guard let driver = drivers.first else {
                    confirmationMessage = "Driver profile not found"
                    showingConfirmation = true
                    return
                }
                
                let requestData: [String: AnyEncodable] = [
                    "vehicle_id": AnyEncodable(vehicle.id),
                    "driver_id": AnyEncodable(driver.id),
                    "service_type": AnyEncodable(selectedServiceType.rawValue),
                    "preferred_date": AnyEncodable(ISO8601DateFormatter().string(from: preferredDate)),
                    "notes": AnyEncodable(notes),
                    "status": AnyEncodable("Pending"),
                    "request_date": AnyEncodable(ISO8601DateFormatter().string(from: Date()))
                ]
                
                try await supabase
                    .from("service_requests")
                    .insert(requestData)
                    .execute()
                
                print("✅ Service request submitted: \(selectedServiceType.rawValue)")
                
                // Show success
                await MainActor.run {
                    confirmationMessage = "Service request for \(selectedServiceType.rawValue) submitted!"
                    showingConfirmation = true
                    
                    // Reset form
                    notes = ""
                    selectedServiceType = .routineMaintenance
                }
                
            } catch {
                print("❌ Failed to submit service request: \(error)")
                await MainActor.run {
                    confirmationMessage = "Failed to submit request. Please try again."
                    showingConfirmation = true
                }
            }
        }
    }
    
    func markItemAsChecked(_ id: UUID) {
        if let index = checklistItems.firstIndex(where: { $0.id == id }) {
            checklistItems[index].isChecked.toggle()
        }
    }
}
