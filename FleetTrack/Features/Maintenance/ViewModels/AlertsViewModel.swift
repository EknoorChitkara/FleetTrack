//
//  AlertsViewModel.swift
//  FleetTrack
//
//  Created for Maintenance Module
//

import Combine
import Foundation

class AlertsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var alerts: [MaintenanceAlert] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var filter: AlertFilter = .all

    enum AlertFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case system = "System"
        case emergency = "Emergency"
    }

    // MARK: - Initialization

    init() {
        Task { await loadAlerts() }
    }

    // MARK: - Data Loading

    @MainActor
    func loadAlerts() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedAlerts = try await MaintenanceService.shared.fetchAlerts()
            self.alerts = fetchedAlerts
            print("✅ Loaded \(fetchedAlerts.count) alerts from Supabase")
        } catch {
            self.errorMessage = "Failed to load alerts: \(error.localizedDescription)"
            print("❌ Error loading alerts: \(error)")
        }

        isLoading = false
    }

    // MARK: - Actions

    @MainActor
    func markAsRead(alertId: UUID) async {
        do {
            try await MaintenanceService.shared.markAlertAsRead(alertId: alertId)
            if let index = alerts.firstIndex(where: { $0.id == alertId }) {
                alerts[index].isRead = true
            }
        } catch {
            self.errorMessage = "Failed to mark alert as read: \(error.localizedDescription)"
        }
    }

    @MainActor
    func deleteAlert(alertId: UUID) async {
        do {
            try await MaintenanceService.shared.deleteAlert(alertId: alertId)
            alerts.removeAll { $0.id == alertId }
        } catch {
            self.errorMessage = "Failed to delete alert: \(error.localizedDescription)"
        }
    }

    // MARK: - Filtered Alerts

    var filteredAlerts: [MaintenanceAlert] {
        switch filter {
        case .all:
            return alerts
        case .unread:
            return alerts.filter { !$0.isRead }
        case .system:
            return alerts.filter { $0.type == .system }
        case .emergency:
            return alerts.filter { $0.type == .emergency }
        }
    }
}
