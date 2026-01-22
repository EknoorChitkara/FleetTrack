//
//  CategoryDetailView.swift
//  FleetTrack
//
//  Created for Inventory Management
//

import SwiftUI

struct CategoryDetailView: View {
    let category: PartCategory
    @EnvironmentObject var viewModel: InventoryViewModel
    @State private var showingAddPart = false
    @State private var partToEdit: InventoryPart?
    
    var categoryParts: [InventoryPart] {
        viewModel.parts(for: category)
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if categoryParts.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(categoryParts) { part in
                            PartRow(part: part)
                                .listRowBackground(AppTheme.backgroundSecondary)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .onTapGesture {
                                    partToEdit = part
                                }
                        }
                        .onDelete { offsets in
                            viewModel.deleteParts(at: offsets, from: categoryParts)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle(viewModel.displayName(for: category))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddPart = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.accentPrimary)
                }
            }
        }
        .sheet(isPresented: $showingAddPart) {
            AddEditPartView(category: category)
                .environmentObject(viewModel)
        }
        .sheet(item: $partToEdit) { part in
            AddEditPartView(partToEdit: part)
                .environmentObject(viewModel)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.icon(for: category))
                .font(.system(size: 60))
                .foregroundColor(AppTheme.iconDefault.opacity(0.5))
            
            Text("No Parts Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textPrimary)
            
            Text("Add parts to this category using the + button")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingAddPart = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Part")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AppTheme.accentPrimary)
                .cornerRadius(AppTheme.cornerRadius.medium)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Part Row Component

struct PartRow: View {
    let part: InventoryPart
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(part.name)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                Spacer()
                
                Text(part.formattedPrice)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.accentPrimary)
            }
            
            HStack {
                // Stock Status
                HStack(spacing: 4) {
                    Image(systemName: "shippingbox.fill")
                        .font(.caption)
                    Text("\(part.quantityInStock) in stock")
                        .font(.caption)
                }
                .foregroundColor(stockStatusColor)
                
                Spacer()
                
                // Stock Status Badge
                Text(part.stockStatus)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(stockStatusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(stockStatusColor.opacity(0.15))
                    .cornerRadius(6)
            }
            
            if let description = part.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            
            if let supplier = part.supplierName {
                HStack(spacing: 4) {
                    Image(systemName: "building.2.fill")
                        .font(.caption2)
                    Text(supplier)
                        .font(.caption)
                }
                .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.vertical, 8)
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
    NavigationStack {
        CategoryDetailView(category: .brakes)
            .environmentObject(InventoryViewModel())
    }
}
