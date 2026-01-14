//
//  ReportIssueViewModel.swift
//  FleetTrack
//
//  Created for Driver
//

import Foundation
import Combine
import SwiftUI

@MainActor
class ReportIssueViewModel: ObservableObject {
    @Published var selectedIssueType: IssueType?
    @Published var selectedSeverity: IssueSeverity = .normal
    @Published var description: String = ""
    @Published var vehicleId: UUID?
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    
    private var driverId: UUID
    
    init(driverId: UUID, vehicleId: UUID?) {
        self.driverId = driverId
        self.vehicleId = vehicleId
    }
    
    var isValid: Bool {
        return selectedIssueType != nil && !description.isEmpty
    }
    
    func submitReport() async {
        guard let type = selectedIssueType, let vId = vehicleId else {
            errorMessage = "Please select an issue type."
            return
        }
        
        if description.isEmpty {
            errorMessage = "Please provide a description."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        
        // Mock successful submission
        // In a real app, this would POST to the backend
        print("🚨 Reporting Issue: \(type.rawValue) - \(selectedSeverity.rawValue)")
        print("Description: \(description)")
        print("Vehicle: \(vId)")
        
        isLoading = false
        isSuccess = true
    }
}
