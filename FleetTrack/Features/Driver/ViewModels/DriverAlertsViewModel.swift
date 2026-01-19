//
//  DriverAlertsViewModel.swift
//  FleetTrack
//
//  Created by FleetTrack on 20/01/26.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class DriverAlertsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var alerts: [MaintenanceAlert] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedTab: AlertTab = .all
    
    // MARK: - Enums
    
    enum AlertTab: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
    }
    
    // MARK: - Dependencies
    
    private let maintenanceService = MaintenanceService.shared
    
    // MARK: - Initialization
    
    init() {
        Task { await loadAlerts() }
    }
    
    // MARK: - Data Loading
    
    func loadAlerts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedAlerts = try await maintenanceService.fetchAlerts()
            self.alerts = fetchedAlerts
        } catch {
            self.errorMessage = "Failed to load alerts: \(error.localizedDescription)"
            // Fallback - mock data if service fails or is not ready
            self.alerts = [
                MaintenanceAlert(title: "Engine Overheat", message: "Engine temperature critical", date: Date(), type: .emergency),
                MaintenanceAlert(title: "Oil Change Due", message: "Scheduled maintenance", date: Date().addingTimeInterval(-86400), type: .maintenance)
            ]
        }
        
        isLoading = false
    }
    
    // MARK: - Computed Properties
    
    // Per user request:
    // "All" tab should show EMERGENCY alerts
    // "Unread" tab should show MAINTENANCE alerts (everything else)
    
    var currentTabAlerts: [MaintenanceAlert] {
        switch selectedTab {
        case .all:
            return emergencyAlerts
        case .unread:
            return maintenanceAlerts
        }
    }
    
    private var emergencyAlerts: [MaintenanceAlert] {
        alerts.filter { $0.type == .emergency }
    }
    
    private var maintenanceAlerts: [MaintenanceAlert] {
        alerts.filter { $0.type != .emergency }
    }
    
    var emergencyCount: Int {
        emergencyAlerts.count
    }
    
    var maintenanceCount: Int {
        maintenanceAlerts.count
    }
    
    // MARK: - Actions
    
    func refresh() async {
        await loadAlerts()
    }
}
