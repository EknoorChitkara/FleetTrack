//
//  InventoryView.swift
//  FleetTrack
//
//  Created for Maintenance Module - Inventory Management
//

import SwiftUI

struct InventoryView: View {
    @State private var searchText: String = ""
    
    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inventory")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Parts & supplies management")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.spacing.md)
                .padding(.vertical, AppTheme.spacing.sm)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.iconDefault)
                    
                    TextField("Search parts...", text: $searchText)
                        .foregroundColor(AppTheme.textPrimary)
                }
                .padding(12)
                .background(AppTheme.backgroundSecondary)
                .cornerRadius(AppTheme.cornerRadius.medium)
                .padding(.horizontal, AppTheme.spacing.md)
                .padding(.bottom, AppTheme.spacing.sm)
                
                // Content
                ScrollView {
                    VStack(spacing: AppTheme.spacing.md) {
                        // Quick Stats
                        quickStatsSection
                        
                        // Categories
                        categoriesSection
                        
                        // Low Stock Alert
                        lowStockSection
                        
                        // Coming Soon Message
                        VStack(spacing: 12) {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 48))
                                .foregroundColor(AppTheme.iconDefault)
                            
                            Text("Inventory Management")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text("Full inventory features coming soon")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                    .padding(AppTheme.spacing.md)
                }
            }
        }
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        HStack(spacing: AppTheme.spacing.sm) {
            StatCard(
                title: "Total Items",
                value: "156",
                icon: "shippingbox.fill",
                color: AppTheme.accentPrimary
            )
            
            StatCard(
                title: "Low Stock",
                value: "12",
                icon: "exclamationmark.triangle.fill",
                color: AppTheme.statusWarning
            )
            
            StatCard(
                title: "Out of Stock",
                value: "3",
                icon: "xmark.circle.fill",
                color: AppTheme.statusError
            )
        }
    }
    
    // MARK: - Categories Section
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            Text("Categories")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            VStack(spacing: AppTheme.spacing.sm) {
                CategoryRow(name: "Engine Parts", count: 45, icon: "engine.combustion.fill")
                CategoryRow(name: "Brake Components", count: 32, icon: "brake.signal")
                CategoryRow(name: "Electrical", count: 28, icon: "bolt.fill")
                CategoryRow(name: "Tires & Wheels", count: 24, icon: "circle.circle.fill")
                CategoryRow(name: "Fluids & Oils", count: 27, icon: "drop.fill")
            }
        }
    }
    
    // MARK: - Low Stock Section
    
    private var lowStockSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            HStack {
                Text("Low Stock Alert")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Text("12 items")
                    .font(.caption)
                    .foregroundColor(AppTheme.statusWarning)
            }
            
            VStack(spacing: AppTheme.spacing.sm) {
                LowStockItem(name: "Brake Pads", current: 4, minimum: 10)
                LowStockItem(name: "Oil Filter", current: 6, minimum: 15)
                LowStockItem(name: "Air Filter", current: 3, minimum: 10)
            }
        }
    }
}

// MARK: - Category Row Component

struct CategoryRow: View {
    let name: String
    let count: Int
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppTheme.accentPrimary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("\(count) items")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.iconDefault)
        }
        .padding(12)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.small)
    }
}

// MARK: - Low Stock Item Component

struct LowStockItem: View {
    let name: String
    let current: Int
    let minimum: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Current: \(current) | Min: \(minimum)")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Text("Low")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.statusWarning)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.statusWarningBackground)
                .cornerRadius(6)
        }
        .padding(12)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.small)
    }
}

#Preview {
    InventoryView()
}
