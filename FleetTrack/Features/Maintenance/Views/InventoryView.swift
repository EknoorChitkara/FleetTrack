//
//  InventoryView.swift
//  FleetTrack
//
//  Created for Maintenance Module - Inventory Management
//

import SwiftUI

struct InventoryView: View {
    @StateObject private var viewModel = InventoryViewModel()
    @State private var showingAddPart = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Inventory")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text("Parts & supplies management")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddPart = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.accentPrimary)
                    }
                }
                .padding(.horizontal, AppTheme.spacing.md)
                .padding(.vertical, AppTheme.spacing.sm)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.iconDefault)
                    
                    TextField("Search parts...", text: $viewModel.searchText)
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
                        // Show search results when searching
                        if !viewModel.searchText.isEmpty {
                            searchResultsSection
                        } else {
                            // Quick Stats
                            quickStatsSection
                            
                            // Categories
                            categoriesSection
                            
                            // Low Stock Alert
                            if !viewModel.lowStockParts.isEmpty {
                                lowStockSection
                            }
                        }
                    }
                    .padding(AppTheme.spacing.md)
                }
            }
        }
        .sheet(isPresented: $showingAddPart) {
            AddEditPartView()
                .environmentObject(viewModel)
        }
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        HStack(spacing: AppTheme.spacing.sm) {
            InventoryStatCard(
                title: "Total Items",
                value: "\(viewModel.totalItems)",
                icon: "shippingbox.fill",
                color: AppTheme.accentPrimary
            )
            
            InventoryStatCard(
                title: "Low Stock",
                value: "\(viewModel.lowStockParts.count)",
                icon: "exclamationmark.triangle.fill",
                color: AppTheme.statusWarning
            )
            
            InventoryStatCard(
                title: "Out of Stock",
                value: "\(viewModel.outOfStockParts.count)",
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
                // Display all categories dynamically
                ForEach(viewModel.allCategories) { category in
                    CategoryRowButton(
                        viewModel: viewModel,
                        category: category,
                        displayName: viewModel.displayName(for: category)
                    )
                }
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
                
                Text("\(viewModel.lowStockParts.count) items")
                    .font(.caption)
                    .foregroundColor(AppTheme.statusWarning)
            }
            
            VStack(spacing: AppTheme.spacing.sm) {
                ForEach(viewModel.lowStockParts.prefix(3)) { part in
                    LowStockItemButton(
                        part: part,
                        viewModel: viewModel
                    )
                }
            }
        }
    }
    
    // MARK: - Search Results Section
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            HStack {
                Text("Search Results")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Text("\(viewModel.filteredParts.count) item\(viewModel.filteredParts.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            if viewModel.filteredParts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.iconDefault.opacity(0.5))
                    
                    Text("No parts found")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Try searching with different keywords")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: AppTheme.spacing.sm) {
                    ForEach(viewModel.filteredParts) { part in
                        SearchResultPartRow(
                            part: part,
                            viewModel: viewModel
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Category Row Button Component

struct CategoryRowButton: View {
    @ObservedObject var viewModel: InventoryViewModel
    let category: PartCategory
    let displayName: String
    
    var count: Int {
        viewModel.categoryCount(for: category)
    }
    
    var icon: String {
        viewModel.icon(for: category)
    }
    
    var body: some View {
        NavigationLink(destination: CategoryDetailView(category: category).environmentObject(viewModel)) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.accentPrimary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
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
}

// MARK: - Low Stock Item Button Component

struct LowStockItemButton: View {
    let part: InventoryPart
    @ObservedObject var viewModel: InventoryViewModel
    @State private var showingEditSheet = false
    
    var body: some View {
        Button(action: {
            showingEditSheet = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(part.name)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Current: \(part.quantityInStock) | Min: \(part.minimumStockLevel)")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("Low")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.statusWarning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.statusWarningBackground)
                        .cornerRadius(6)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppTheme.iconDefault)
                }
            }
            .padding(12)
            .background(AppTheme.backgroundSecondary)
            .cornerRadius(AppTheme.cornerRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingEditSheet) {
            AddEditPartView(partToEdit: part)
                .environmentObject(viewModel)
        }
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

// MARK: - Inventory Stat Card Component

struct InventoryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
}

// MARK: - Search Result Part Row Component

struct SearchResultPartRow: View {
    let part: InventoryPart
    @ObservedObject var viewModel: InventoryViewModel
    @State private var showingEditSheet = false
    
    var body: some View {
        Button(action: {
            showingEditSheet = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(part.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    HStack(spacing: 8) {
                        Text(part.partNumber)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text(viewModel.displayName(for: part.category))
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "shippingbox.fill")
                            .font(.caption2)
                        Text("\(part.quantityInStock) in stock")
                            .font(.caption)
                    }
                    .foregroundColor(stockStatusColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(part.formattedPrice)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.accentPrimary)
                    
                    Text(part.stockStatus)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(stockStatusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(stockStatusColor.opacity(0.15))
                        .cornerRadius(6)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.iconDefault)
            }
            .padding(12)
            .background(AppTheme.backgroundSecondary)
            .cornerRadius(AppTheme.cornerRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingEditSheet) {
            AddEditPartView(partToEdit: part)
                .environmentObject(viewModel)
        }
    }
    
    private var stockStatusColor: Color {
        if part.quantityInStock == 0 {
            return AppTheme.statusError
        } else if part.isLowStock {
            return AppTheme.statusWarning
        } else {
            return AppTheme.statusActiveText
        }
    }
}

#Preview {
    InventoryView()
}
