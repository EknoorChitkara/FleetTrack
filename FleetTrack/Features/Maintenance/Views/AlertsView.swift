//
//  AlertsView.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import SwiftUI

struct AlertsView: View {
    var alerts: [MaintenanceAlert] = [] // Passed from parent
    @StateObject private var inventoryViewModel = InventoryViewModel()
    @State private var selectedFilter: AlertFilter = .all
    @State private var partToEdit: InventoryPart?
    @State private var selectedAlert: MaintenanceAlert?

    enum AlertFilter: String, CaseIterable {
        case all = "All"
        case lowStock = "Low Stock"
    }

    var filteredParts: [InventoryPart] {
        switch selectedFilter {
        case .all:
            return inventoryViewModel.lowStockParts
        case .lowStock:
            return inventoryViewModel.lowStockParts
        }
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alerts")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Inventory alerts and notifications")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.spacing.md)
                .padding(.vertical, AppTheme.spacing.sm)

                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(AlertFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.spacing.md)
                .padding(.bottom, AppTheme.spacing.sm)
                .accessibilityLabel("Filter alerts")
                .accessibilityIdentifier("maintenance_alerts_filter")

                // Alerts List
                // Alerts List
                ScrollView {
                    VStack(spacing: AppTheme.spacing.sm) {
                        
                        // 1. Maintenance/Emergency Alerts
                        if selectedFilter == .all && !alerts.isEmpty {
                            ForEach(alerts) { alert in
                                MaintenanceAlertCard(alert: alert)
                                    .onTapGesture {
                                        if alert.type == .emergency {
                                            selectedAlert = alert
                                        }
                                    }
                            }
                        }
                        
                        // 2. Inventory Alerts
                        if inventoryViewModel.isLoading {
                            VStack {
                                Spacer()
                                ProgressView()
                                    .tint(AppTheme.accentPrimary)
                                Text("Checking inventory...")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .padding(.top, 8)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if filteredParts.isEmpty && (selectedFilter != .all || alerts.isEmpty) {
                            // Show empty state if NO alerts at all for current filter
                            // If selectedFilter is .all, we only show empty if BOTH are empty
                            // If selectedFilter is inventory-specific, we show if parts are empty
                            emptyStateView
                        } else {
                            ForEach(filteredParts) { part in
                                InventoryAlertCard(
                                    part: part,
                                    onTap: {
                                        partToEdit = part
                                    }
                                )
                            }
                        }
                    }
                    .padding(AppTheme.spacing.md)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await inventoryViewModel.loadInventory()
                }
                .task {
                    await inventoryViewModel.loadInventory()
                }
            }
        }
        .sheet(item: $partToEdit) { part in
            AddEditPartView(partToEdit: part)
                .environmentObject(inventoryViewModel)
        }
        .sheet(item: $selectedAlert) { alert in
            EmergencyAlertDetailView(alert: alert)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.statusActiveText)

            Text("All Good!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textPrimary)

            Text("No inventory alerts at this time")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Inventory Alert Card

struct InventoryAlertCard: View {
    let part: InventoryPart
    let onTap: () -> Void

    var alertType: String {
        if part.quantityInStock == 0 {
            return "OUT OF STOCK"
        } else {
            return "LOW STOCK"
        }
    }

    var alertColor: Color {
        part.quantityInStock == 0 ? AppTheme.statusError : AppTheme.statusWarning
    }

    var alertIcon: String {
        part.quantityInStock == 0 ? "xmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Alert Type Badge
                HStack {
                    Image(systemName: alertIcon)
                        .font(.system(size: 14))
                        .foregroundColor(alertColor)

                    Text(alertType)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(alertColor)

                    Spacer()

                    Text(part.category.rawValue)
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.backgroundElevated)
                        .cornerRadius(6)
                }

                // Part Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(part.name)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "shippingbox.fill")
                                .font(.caption)
                            Text("Current: \(part.quantityInStock)")
                                .font(.caption)
                        }
                        .foregroundColor(alertColor)

                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.downtrend.xyaxis")
                                .font(.caption)
                            Text("Min: \(part.minimumStockLevel)")
                                .font(.caption)
                        }
                        .foregroundColor(AppTheme.textSecondary)
                    }
                }

                // Supplier Info (if available)
                if let supplier = part.supplierName {
                    Divider()
                        .background(AppTheme.dividerPrimary)

                    HStack {
                        Image(systemName: "building.2.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.iconDefault)

                        Text(supplier)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                // Action hint
                HStack {
                    Text("Tap to update stock")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textTertiary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(AppTheme.iconDefault)
                }
            }
            .padding(AppTheme.spacing.md)
            .background(AppTheme.backgroundSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius.medium)
                    .stroke(alertColor.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(AppTheme.cornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(alertType) Alert: \(part.name). Stock: \(part.quantityInStock). Category: \(part.category.rawValue).")
        .accessibilityHint("Double tap to update stock")
        .accessibilityIdentifier("maintenance_inventory_alert_\(part.id.uuidString.prefix(8))")
    }
}

// MARK: - Maintenance Alert Card

struct MaintenanceAlertCard: View {
    let alert: MaintenanceAlert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.statusError)
                
                Text(alert.type.rawValue.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.statusError)
                
                Spacer()
                
                Text(alert.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(alert.title)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                // Parse severity and description from message
                VStack(alignment: .leading, spacing: 4) {
                    if alert.message.contains("Severity:") {
                        let components = alert.message.components(separatedBy: ". ")
                        if let severityPart = components.first {
                            // Remove period from severity
                            Text(severityPart.replacingOccurrences(of: ".", with: ""))
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        if components.count > 1 {
                            Text(components.dropFirst().joined(separator: ". "))
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    } else {
                        Text(alert.message)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
        }
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius.medium)
                .stroke(AppTheme.statusError.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(AppTheme.cornerRadius.medium)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Maintenance Alert: \(alert.title). Type: \(alert.type.rawValue). Date: \(alert.date.formatted(date: .abbreviated, time: .shortened)).")
        .accessibilityIdentifier("maintenance_system_alert_\(alert.id.uuidString.prefix(8))")
    }
}

#Preview {
    AlertsView()
}
