//
//  AlertsView.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import SwiftUI

struct AlertsView: View {
    @StateObject private var inventoryViewModel = InventoryViewModel()
    @State private var selectedFilter: AlertFilter = .all
    @State private var partToEdit: InventoryPart?
    
    enum AlertFilter: String, CaseIterable {
        case all = "All"
        case outOfStock = "Out of Stock"
        case lowStock = "Low Stock"
    }
    
    var filteredParts: [InventoryPart] {
        switch selectedFilter {
        case .all:
            return inventoryViewModel.lowStockParts + inventoryViewModel.outOfStockParts
        case .outOfStock:
            return inventoryViewModel.outOfStockParts
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
                
                // Alerts List
                if filteredParts.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.spacing.sm) {
                            ForEach(filteredParts) { part in
                                InventoryAlertCard(
                                    part: part,
                                    onTap: {
                                        partToEdit = part
                                    }
                                )
                            }
                        }
                        .padding(AppTheme.spacing.md)
                    }
                }
            }
        }
        .sheet(item: $partToEdit) { part in
            AddEditPartView(partToEdit: part)
                .environmentObject(inventoryViewModel)
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

// MARK: - Alert Stat Card

struct AlertStatCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
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
    
    var alertBackground: Color {
        part.quantityInStock == 0 ? AppTheme.statusErrorBackground : AppTheme.statusWarningBackground
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
                    
                    Text(part.partNumber)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
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
    }
}

#Preview {
    AlertsView()
}
