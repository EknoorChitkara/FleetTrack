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
    @State private var showingScanner = false
    @State private var scannedData: ScannedPartData? = nil
    
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
                    Section(header: Text("Basic Information").accessibilityAddTraits(.isHeader)) {
                        TextField("Part Name", text: $name)
                            .foregroundColor(AppTheme.textPrimary)
                            .onChange(of: name) { newValue in
                                // Allow only letters, spaces, and hyphens, max 50 characters
                                let filtered = newValue.filter { $0.isLetter || $0.isWhitespace || $0 == "-" }
                                if filtered.count > 50 {
                                    name = String(filtered.prefix(50))
                                } else if filtered != newValue {
                                    name = filtered
                                }
                            }
                        
                        
                        HStack {
                            TextField("Part Number", text: $partNumber)
                                .foregroundColor(AppTheme.textPrimary)
                                .autocapitalization(.allCharacters)
                                .onChange(of: partNumber) { newValue in
                                    // Allow only uppercase letters and numbers, max 20 characters
                                    let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                                    if filtered.count > 20 {
                                        partNumber = String(filtered.prefix(20))
                                    } else if filtered != newValue {
                                        partNumber = filtered
                                    }
                                }
                            
                            Button(action: {
                                showingScanner = true
                            }) {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.title2)
                                    .foregroundColor(AppTheme.accentPrimary)
                                    .padding(8)
                                    .background(AppTheme.backgroundElevated)
                                    .cornerRadius(8)
                            }
                        }
                        
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
                        .accessibilityLabel("Category")
                        .accessibilityIdentifier("maintenance_part_category_picker")
                        
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
                        .accessibilityLabel("Create New Category")
                        .accessibilityIdentifier("maintenance_part_new_category_button")
                        
                        TextField("Description (Optional)", text: $description, axis: .vertical)
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(3...6)
                            .accessibilityLabel("Description")
                            .accessibilityIdentifier("maintenance_part_description_input")
                    }
                    .listRowBackground(AppTheme.backgroundSecondary)
                    
                    Section(header: Text("Stock Information").accessibilityAddTraits(.isHeader)) {
                        HStack {
                            Text("Quantity in Stock")
                            Spacer()
                            TextField("0", text: $quantityInStock)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(AppTheme.textPrimary)
                                .onChange(of: quantityInStock) { newValue in
                                    // Allow only numbers, max 5 digits
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered.count > 5 {
                                        quantityInStock = String(filtered.prefix(5))
                                    } else if filtered != newValue {
                                        quantityInStock = filtered
                                    }
                                }
                                .frame(width: 100)
                        }
                        
                        HStack {
                            Text("Minimum Stock Level")
                            Spacer()
                            TextField("5", text: $minimumStockLevel)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(AppTheme.textPrimary)
                                .onChange(of: minimumStockLevel) { newValue in
                                    // Allow only numbers, max 2 digits
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered.count > 2 {
                                        minimumStockLevel = String(filtered.prefix(2))
                                    } else if filtered != newValue {
                                        minimumStockLevel = filtered
                                    }
                                }
                                .frame(width: 100)
                        }
                    }
                    .listRowBackground(AppTheme.backgroundSecondary)
                    
                    Section(header: Text("Pricing").accessibilityAddTraits(.isHeader)) {
                        HStack {
                            Text("Unit Price (₹)")
                            Spacer()
                            TextField("0.00", text: $unitPrice)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(AppTheme.textPrimary)
                                .onChange(of: unitPrice) { newValue in
                                    // Allow only numbers and one decimal point, max 8 digits total
                                    let filtered = newValue.filter { $0.isNumber || $0 == "." }
                                    // Remove decimal to count digits
                                    let digitsOnly = filtered.filter { $0.isNumber }
                                    
                                    if digitsOnly.count > 8 {
                                        // Limit to 8 digits
                                        let parts = filtered.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
                                        if parts.count == 2 {
                                            let intPart = String(parts[0].filter { $0.isNumber }.prefix(8))
                                            let decPart = String(parts[1].filter { $0.isNumber })
                                            let totalDigits = intPart.count + decPart.count
                                            if totalDigits > 8 {
                                                unitPrice = intPart + "." + String(decPart.prefix(8 - intPart.count))
                                            } else {
                                                unitPrice = intPart + "." + decPart
                                            }
                                        } else {
                                            unitPrice = String(digitsOnly.prefix(8))
                                        }
                                    } else {
                                        // Ensure only one decimal point
                                        let decimalCount = filtered.filter { $0 == "." }.count
                                        if decimalCount <= 1 && filtered != newValue {
                                            unitPrice = filtered
                                        } else if decimalCount > 1 {
                                            unitPrice = String(filtered.prefix(while: { $0 != "." })) + "." + filtered.drop(while: { $0 != "." }).dropFirst().filter { $0 != "." }
                                        }
                                    }
                                }
                                .frame(width: 120)
                        }
                    }
                    .listRowBackground(AppTheme.backgroundSecondary)
                    
                    Section(header: Text("Supplier Information (Optional)").accessibilityAddTraits(.isHeader)) {
                        TextField("Supplier Name", text: $supplierName)
                            .foregroundColor(AppTheme.textPrimary)
                            .onChange(of: supplierName) { newValue in
                                // Allow only letters, spaces, hyphens, and ampersand
                                let filtered = newValue.filter { $0.isLetter || $0.isWhitespace || $0 == "-" || $0 == "&" }
                                if filtered != newValue {
                                    supplierName = filtered
                                }
                            }
                        
                        TextField("Supplier Contact", text: $supplierContact)
                            .foregroundColor(AppTheme.textPrimary)
                            .keyboardType(.phonePad)
                            .onChange(of: supplierContact) { newValue in
                                // Allow only numbers, +, -, (, ), and spaces for phone format
                                let filtered = newValue.filter { $0.isNumber || $0 == "+" || $0 == "-" || $0 == "(" || $0 == ")" || $0.isWhitespace }
                                // Limit to 15 characters (international phone number max)
                                if filtered.count > 15 {
                                    supplierContact = String(filtered.prefix(15))
                                } else if filtered != newValue {
                                    supplierContact = filtered
                                }
                            }
                    }
                    .listRowBackground(AppTheme.backgroundSecondary)
                }
                .scrollContentBackground(.hidden)
                .textInputAutocapitalization(.never)
            }
            .navigationTitle(isEditMode ? "Edit Part" : "Add Part")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("maintenance_add_edit_part_view")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditMode ? "Update" : "Save") {
                        savePart()
                    }
                }
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .alert("Add Category", isPresented: $showingAddCategory) {
                TextField("Category Name", text: $newCategoryName)
                Button("Cancel", role: .cancel) { }
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
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerView(scannedData: $scannedData)
            }
            .onChange(of: scannedData) { newData in
                handleScannedData(newData)
            }
            .onAppear {
                loadPartData()
            }
        }
    }
    
    private func handleScannedData(_ newData: ScannedPartData?) {
        guard let data = newData else { return }
        
        if let partName = data.partName {
            name = partName
        }
        if let partNum = data.partNumber {
            partNumber = partNum
        }
        if let qty = data.quantity {
            quantityInStock = "\(qty)"
        }
        if let supplier = data.supplierName {
            supplierName = supplier
        }
        if let price = data.unitPrice {
            unitPrice = String(format: "%.2f", price)
        }
        if let desc = data.description {
            description = desc
        }
        
        print("✅ Auto-filled fields from scanned data")
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
        
        // Check for duplicate part name (case-insensitive)
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let existingPart = viewModel.parts.first { part in
            part.name.lowercased() == trimmedName.lowercased() && part.id != partToEdit?.id
        }
        
        if let existing = existingPart {
            validationMessage = "A part named '\(existing.name)' already exists in inventory. Please update the existing part or use a different name."
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
