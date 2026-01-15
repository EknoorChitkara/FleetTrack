//
//  AddEditPartView.swift
//  FleetTrack
//
//  Created for Inventory Management
//

import SwiftUI

struct AddEditPartView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: InventoryViewModel
    
    let partToEdit: InventoryPart?
    let preselectedCategory: PartCategory?
    
    // Form fields
    @State private var name: String = ""
    @State private var partNumber: String = ""
    @State private var category: PartCategory = .other
    @State private var description: String = ""
    @State private var quantityInStock: String = "0"
    @State private var minimumStockLevel: String = "5"
    @State private var unitPrice: String = "0"
    @State private var supplierName: String = ""
    @State private var supplierContact: String = ""
    
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    
    var isEditMode: Bool {
        partToEdit != nil
    }
    
    init(partToEdit: InventoryPart? = nil, category: PartCategory? = nil) {
        self.partToEdit = partToEdit
        self.preselectedCategory = category
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                Form {
                    Section(header: Text("Basic Information")) {
                        TextField("Part Name", text: $name)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        TextField("Part Number", text: $partNumber)
                            .foregroundColor(AppTheme.textPrimary)
                            .autocapitalization(.allCharacters)
                        
                        Picker("Category", selection: $category) {
                            ForEach(viewModel.allCategories) { cat in
                                HStack {
                                    Image(systemName: viewModel.icon(for: cat))
                                    Text(viewModel.displayName(for: cat))
                                }
                                .tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(AppTheme.textPrimary)
                        
                        // Create New Category Button
                        Button(action: {
                            showingAddCategory = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.subheadline)
                                Text("Create New Category")
                                    .font(.subheadline)
                                Spacer()
                            }
                            .foregroundColor(AppTheme.accentPrimary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(AppTheme.backgroundElevated)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        TextField("Description (Optional)", text: $description, axis: .vertical)
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(3...6)
                    }
                    .listRowBackground(AppTheme.backgroundSecondary)
                    
                    Section(header: Text("Stock Information")) {
                        HStack {
                            Text("Quantity in Stock")
                            Spacer()
                            TextField("0", text: $quantityInStock)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(width: 100)
                        }
                        
                        HStack {
                            Text("Minimum Stock Level")
                            Spacer()
                            TextField("5", text: $minimumStockLevel)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(width: 100)
                        }
                    }
                    .listRowBackground(AppTheme.backgroundSecondary)
                    
                    Section(header: Text("Pricing")) {
                        HStack {
                            Text("Unit Price (₹)")
                            Spacer()
                            TextField("0.00", text: $unitPrice)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(width: 120)
                        }
                    }
                    .listRowBackground(AppTheme.backgroundSecondary)
                    
                    Section(header: Text("Supplier Information (Optional)")) {
                        TextField("Supplier Name", text: $supplierName)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        TextField("Supplier Contact", text: $supplierContact)
                            .foregroundColor(AppTheme.textPrimary)
                            .keyboardType(.phonePad)
                    }
                    .listRowBackground(AppTheme.backgroundSecondary)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditMode ? "Edit Part" : "Add New Part")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePart()
                    }
                    .foregroundColor(AppTheme.accentPrimary)
                    .fontWeight(.semibold)
                }
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .alert("Add New Category", isPresented: $showingAddCategory) {
                TextField("Category Name", text: $newCategoryName)
                Button("Cancel", role: .cancel) {
                    newCategoryName = ""
                }
                Button("Add") {
                    if !newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty {
                        viewModel.addCustomCategory(newCategoryName.trimmingCharacters(in: .whitespaces))
                        let customCat = PartCategory.custom(newCategoryName.trimmingCharacters(in: .whitespaces))
                        category = customCat
                        newCategoryName = ""
                    }
                }
            } message: {
                Text("Enter a name for the new category")
            }
            .onAppear {
                loadPartData()
            }
        }
    }
    
    private func loadPartData() {
        if let part = partToEdit {
            // Edit mode - load existing data
            name = part.name
            partNumber = part.partNumber
            category = part.category
            description = part.description ?? ""
            quantityInStock = "\(part.quantityInStock)"
            minimumStockLevel = "\(part.minimumStockLevel)"
            unitPrice = String(format: "%.2f", part.unitPrice)
            supplierName = part.supplierName ?? ""
            supplierContact = part.supplierContact ?? ""
        } else if let preselected = preselectedCategory {
            // Add mode with preselected category
            category = preselected
        }
    }
    
    private func savePart() {
        // Validate required fields
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "Please enter a part name"
            showingValidationError = true
            return
        }
        
        guard !partNumber.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "Please enter a part number"
            showingValidationError = true
            return
        }
        
        // Parse numeric fields
        guard let quantity = Int(quantityInStock) else {
            validationMessage = "Please enter a valid quantity"
            showingValidationError = true
            return
        }
        
        guard let minStock = Int(minimumStockLevel) else {
            validationMessage = "Please enter a valid minimum stock level"
            showingValidationError = true
            return
        }
        
        guard let price = Double(unitPrice) else {
            validationMessage = "Please enter a valid price"
            showingValidationError = true
            return
        }
        
        // Create or update part
        let part = InventoryPart(
            id: partToEdit?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            partNumber: partNumber.trimmingCharacters(in: .whitespaces),
            category: category,
            description: description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
            quantityInStock: quantity,
            minimumStockLevel: minStock,
            unitPrice: price,
            supplierName: supplierName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : supplierName.trimmingCharacters(in: .whitespaces),
            supplierContact: supplierContact.trimmingCharacters(in: .whitespaces).isEmpty ? nil : supplierContact.trimmingCharacters(in: .whitespaces),
            isActive: partToEdit?.isActive ?? true,
            createdAt: partToEdit?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        if isEditMode {
            viewModel.updatePart(part)
        } else {
            viewModel.addPart(part)
        }
        
        dismiss()
    }
}

#Preview {
    AddEditPartView()
        .environmentObject(InventoryViewModel())
}

#Preview("Edit Mode") {
    AddEditPartView(partToEdit: InventoryPart.mockPart1)
        .environmentObject(InventoryViewModel())
}
