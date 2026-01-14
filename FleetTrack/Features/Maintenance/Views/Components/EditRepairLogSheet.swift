//
//  EditRepairLogSheet.swift
//  FleetTrack
//
//  Created for Maintenance Module - Task Management
//

import SwiftUI

struct EditRepairLogSheet: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var repairDescription: String
    @State private var laborHours: String
    @State private var partsUsed: [PartUsage]
    @State private var showingAddPartSheet: Bool = false
    
    init(viewModel: TaskDetailViewModel) {
        self.viewModel = viewModel
        _repairDescription = State(initialValue: viewModel.task.repairDescription ?? "")
        _laborHours = State(initialValue: viewModel.task.laborHours != nil ? String(format: "%.1f", viewModel.task.laborHours!) : "")
        _partsUsed = State(initialValue: viewModel.task.partsUsed)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.spacing.lg) {
                        if viewModel.task.isLocked {
                            // Locked message
                            HStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                Text("This task is locked and cannot be edited")
                                    .font(.caption)
                            }
                            .foregroundColor(AppTheme.statusError)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.statusErrorBackground)
                            .cornerRadius(AppTheme.cornerRadius.small)
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                            Text("Repair Description")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            TextEditor(text: $repairDescription)
                                .frame(height: 100)
                                .padding(8)
                                .background(AppTheme.backgroundSecondary)
                                .cornerRadius(AppTheme.cornerRadius.small)
                                .foregroundColor(AppTheme.textPrimary)
                                .disabled(viewModel.task.isLocked)
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                            Text("Labor Hours")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            TextField("e.g., 2.5", text: $laborHours)
                                .keyboardType(.decimalPad)
                                .padding(12)
                                .background(AppTheme.backgroundSecondary)
                                .cornerRadius(AppTheme.cornerRadius.small)
                                .foregroundColor(AppTheme.textPrimary)
                                .disabled(viewModel.task.isLocked)
                        }
                        
                        // Parts Used Section
                        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
                            HStack {
                                Text("Parts Used")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Spacer()
                                
                                if !viewModel.task.isLocked {
                                    Button(action: {
                                        showingAddPartSheet = true
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(AppTheme.accentPrimary)
                                    }
                                }
                            }
                            
                            if partsUsed.isEmpty {
                                Text("No parts added yet")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textTertiary)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(Array(partsUsed.enumerated()), id: \.element.partName) { index, part in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(part.partName)
                                                .font(.subheadline)
                                                .foregroundColor(AppTheme.textPrimary)
                                            
                                            Text("Qty: \(part.quantity) × ₹\(Int(part.unitPrice))")
                                                .font(.caption)
                                                .foregroundColor(AppTheme.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("₹\(Int(part.totalCost))")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(AppTheme.accentPrimary)
                                        
                                        if !viewModel.task.isLocked {
                                            Button(action: {
                                                partsUsed.remove(at: index)
                                            }) {
                                                Image(systemName: "trash.fill")
                                                    .foregroundColor(AppTheme.statusError)
                                                    .font(.caption)
                                            }
                                            .padding(.leading, 8)
                                        }
                                    }
                                    .padding(12)
                                    .background(AppTheme.backgroundSecondary)
                                    .cornerRadius(AppTheme.cornerRadius.small)
                                }
                            }
                            
                            // Total
                            if !partsUsed.isEmpty {
                                HStack {
                                    Text("Total Parts Cost")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text("₹\(Int(partsUsed.reduce(0) { $0 + $1.totalCost }))")
                                        .font(.headline)
                                        .foregroundColor(AppTheme.accentPrimary)
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        if !viewModel.task.isLocked {
                            Button(action: {
                                Task {
                                    await viewModel.updateRepairLog(
                                        description: repairDescription,
                                        laborHours: Double(laborHours) ?? 0,
                                        partsUsed: partsUsed
                                    )
                                    dismiss()
                                }
                            }) {
                                Text("Save Changes")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.accentPrimary)
                                    .cornerRadius(AppTheme.cornerRadius.medium)
                            }
                        }
                    }
                    .padding(AppTheme.spacing.md)
                }
            }
            .navigationTitle("Edit Repair Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentPrimary)
                }
            }
            .sheet(isPresented: $showingAddPartSheet) {
                AddPartSheet(partsUsed: $partsUsed)
            }
        }
    }
}

struct AddPartSheet: View {
    @Binding var partsUsed: [PartUsage]
    @Environment(\.dismiss) var dismiss
    
    @State private var partName: String = ""
    @State private var quantity: String = "1"
    @State private var unitPrice: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.spacing.lg) {
                    VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                        Text("Part Name *")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextField("e.g., Brake Pads", text: $partName)
                            .padding(12)
                            .background(AppTheme.backgroundSecondary)
                            .cornerRadius(AppTheme.cornerRadius.small)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    HStack(spacing: AppTheme.spacing.md) {
                        VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                            Text("Quantity *")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            TextField("1", text: $quantity)
                                .keyboardType(.numberPad)
                                .padding(12)
                                .background(AppTheme.backgroundSecondary)
                                .cornerRadius(AppTheme.cornerRadius.small)
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                            Text("Unit Price (₹) *")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            TextField("0.00", text: $unitPrice)
                                .keyboardType(.decimalPad)
                                .padding(12)
                                .background(AppTheme.backgroundSecondary)
                                .cornerRadius(AppTheme.cornerRadius.small)
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                    
                    if let qty = Int(quantity), let price = Double(unitPrice), !partName.isEmpty {
                        HStack {
                            Text("Total Cost")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("₹\(Int(Double(qty) * price))")
                                .font(.headline)
                                .foregroundColor(AppTheme.accentPrimary)
                        }
                        .padding(12)
                        .background(AppTheme.backgroundElevated)
                        .cornerRadius(AppTheme.cornerRadius.small)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if !partName.isEmpty,
                           let qty = Int(quantity),
                           let price = Double(unitPrice) {
                            let newPart = PartUsage(
                                partName: partName,
                                quantity: qty,
                                unitPrice: price
                            )
                            partsUsed.append(newPart)
                            dismiss()
                        }
                    }) {
                        Text("Add Part")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                (!partName.isEmpty && Int(quantity) != nil && Double(unitPrice) != nil)
                                    ? AppTheme.accentPrimary
                                    : AppTheme.textTertiary
                            )
                            .cornerRadius(AppTheme.cornerRadius.medium)
                    }
                    .disabled(partName.isEmpty || Int(quantity) == nil || Double(unitPrice) == nil)
                }
                .padding(AppTheme.spacing.md)
            }
            .navigationTitle("Add Part")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentPrimary)
                }
            }
        }
    }
}
