//
//  TaskDetailView.swift
//  FleetTrack
//
//  Created for Maintenance Module - Task Management
//

import SwiftUI

struct TaskDetailView: View {
    @StateObject private var viewModel: TaskDetailViewModel
    
    init(task: MaintenanceTask) {
        _viewModel = StateObject(wrappedValue: TaskDetailViewModel(task: task))
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.spacing.lg) {
                    // Task Info Card
                    taskInfoCard
                    
                    // Status Section with Action Buttons
                    statusSection
                    
                    // Vehicle Info
                    vehicleInfoCard
                    
                    // Driver Contact
                    driverContactSection
                    
                    // Parts & Costs Section
                    partsAndCostsSection
                    
                    // Repair Log (if available)
                    if let repairDesc = viewModel.task.repairDescription {
                        repairLogCard(repairDesc)
                    }
                }
                .padding(AppTheme.spacing.md)
            }
            
            // Loading Overlay
            if viewModel.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                ProgressView()
                    .tint(AppTheme.accentPrimary)
                    .scaleEffect(1.5)
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if !viewModel.task.isLocked {
                        Button(action: {
                            viewModel.showingRescheduleSheet = true
                        }) {
                            Label("Reschedule Task", systemImage: "calendar.badge.clock")
                        }
                        
                        Button(role: .destructive, action: {
                            viewModel.showingCancelSheet = true
                        }) {
                            Label("Cancel Task", systemImage: "xmark.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppTheme.accentPrimary)
                }
                .disabled(viewModel.task.isLocked)
            }
        }
        .sheet(isPresented: $viewModel.showingCompletionSheet) {
            CompletionSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingFailureSheet) {
            FailureSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingRescheduleSheet) {
            RescheduleSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingCancelSheet) {
            CancelTaskSheet(viewModel: viewModel)
        }
        .alert("Complete Task?", isPresented: $viewModel.showingCompletionConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Complete") {
                viewModel.showingCompletionSheet = true
            }
        } message: {
            Text("Are you sure you want to mark this task as completed? You will need to provide repair details and labor hours.")
        }
        .sheet(isPresented: $viewModel.showingEditRepairLogSheet) {
            EditRepairLogSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingAddPartSheet) {
            AddPartSheetForTask(viewModel: viewModel)
        }
        .task {
            await viewModel.loadAssignedDriver()
        }
    }
    
    // MARK: - Task Info Card
    
    private var taskInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            Text("Task Information")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            VStack(spacing: AppTheme.spacing.sm) {
                InfoRow(icon: "number", label: "Task ID", value: viewModel.task.id.uuidString.prefix(8).uppercased())
                InfoRow(icon: viewModel.task.taskType.icon, label: "Type", value: viewModel.task.taskType.rawValue)
                InfoRow(icon: "wrench.and.screwdriver", label: "Component", value: viewModel.task.component.rawValue)
                InfoRow(icon: "exclamationmark.triangle", label: "Priority", value: viewModel.task.priority.rawValue)
                InfoRow(icon: "calendar", label: "Due Date", value: formattedDate(viewModel.task.dueDate))
                
                if let description = viewModel.task.description {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
    
    // MARK: - Status Section with Actions
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            Text("Status & Actions")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            // Current Status
            StatusBadge(status: viewModel.task.status, task: viewModel.task)
            
            // Action Buttons based on current status
            VStack(spacing: AppTheme.spacing.sm) {
                if viewModel.task.canBeStarted {
                    ActionButton(
                        title: "Start Task",
                        icon: "play.circle.fill",
                        color: AppTheme.accentPrimary
                    ) {
                        Task { await viewModel.startTask() }
                    }
                }
                
                if viewModel.task.canBePaused {
                    HStack(spacing: AppTheme.spacing.sm) {
                        ActionButton(
                            title: "Pause",
                            icon: "pause.circle.fill",
                            color: AppTheme.statusWarning
                        ) {
                            Task { await viewModel.pauseTask() }
                        }
                        
                        ActionButton(
                            title: "Complete",
                            icon: "checkmark.circle.fill",
                            color: AppTheme.statusActiveText
                        ) {
                            viewModel.showingCompletionConfirmation = true
                        }
                    }
                    
                    ActionButton(
                        title: "Mark as Failed",
                        icon: "xmark.circle.fill",
                        color: AppTheme.statusError
                    ) {
                        viewModel.showingFailureSheet = true
                    }
                }
                
                if viewModel.task.canBeResumed {
                    ActionButton(
                        title: "Resume Task",
                        icon: "play.circle.fill",
                        color: AppTheme.accentPrimary
                    ) {
                        Task { await viewModel.resumeTask() }
                    }
                }
            }
            .frame(minHeight: 50)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
    
    // MARK: - Vehicle Info Card
    
    private var vehicleInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            Text("Vehicle Information")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            VStack(spacing: AppTheme.spacing.sm) {
                // Show vehicle name if available
                if let vehicle = viewModel.assignedVehicle {
                    InfoRow(icon: "car.fill", label: "Vehicle", value: "\(vehicle.manufacturer) \(vehicle.model)")
                }
                
                InfoRow(icon: "number", label: "Registration", value: viewModel.task.vehicleRegistrationNumber)
            }
        }
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
    
    // MARK: - Driver Contact Section
    
    
    private var driverContactSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            Text("Driver Contact")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            if let driver = viewModel.assignedDriver {
                // Real driver data
                VStack(spacing: AppTheme.spacing.sm) {
                    InfoRow(icon: "person.fill", label: "Driver", value: driver.fullName)
                    
                    if let phone = driver.phoneNumber, !phone.isEmpty {
                        InfoRow(icon: "phone.fill", label: "Phone", value: phone)
                        
                        // Call Button
                        Button(action: {
                            if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 16))
                                
                                Text("Call Driver")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppTheme.accentPrimary)
                            .cornerRadius(AppTheme.cornerRadius.medium)
                        }
                        .padding(.top, 4)
                    }
                    
                    InfoRow(icon: "envelope.fill", label: "Email", value: driver.email)
                }
            } else if viewModel.task.assignedDriverId != nil {
                // Loading state
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.accentPrimary))
                    Spacer()
                }
                .padding(.vertical, AppTheme.spacing.md)
            } else {
                // No driver assigned - show placeholder rows for consistency
                VStack(spacing: AppTheme.spacing.sm) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(AppTheme.iconDefault)
                            .frame(width: 24)
                        Text("Driver")
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                        Text("Not assigned")
                            .foregroundColor(AppTheme.textTertiary)
                            .italic()
                    }
                    
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(AppTheme.iconDefault)
                            .frame(width: 24)
                        Text("Phone")
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                        Text("—")
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(AppTheme.iconDefault)
                            .frame(width: 24)
                        Text("Email")
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                        Text("—")
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
            }
        }
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
    
    // MARK: - Parts & Costs Section
    
    private var partsAndCostsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            HStack {
                Text("Parts & Costs")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                if !viewModel.task.isLocked {
                    Button(action: {
                        viewModel.showingAddPartSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Add Part")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(AppTheme.accentPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.backgroundElevated)
                        .cornerRadius(6)
                    }
                }
            }
            
            if viewModel.task.partsUsed.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.iconDefault)
                    
                    Text("No parts added yet")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textTertiary)
                    
                    if !viewModel.task.isLocked {
                        Text("Tap 'Add Part' to log parts used")
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: AppTheme.spacing.sm) {
                    ForEach(Array(viewModel.task.partsUsed.enumerated()), id: \.element.partName) { index, part in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(part.partName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
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
                                    Task {
                                        await viewModel.removePart(at: index)
                                    }
                                }) {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(AppTheme.statusError)
                                        .font(.caption)
                                        .padding(8)
                                }
                            }
                        }
                        .padding(12)
                        .background(AppTheme.backgroundElevated)
                        .cornerRadius(AppTheme.cornerRadius.small)
                    }
                }
                
                // Parts Total (only if parts exist)
                VStack(spacing: 8) {
                    Divider()
                        .background(AppTheme.dividerPrimary)
                    
                    HStack {
                        Text("Total Parts Cost")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Spacer()
                        
                        Text("₹\(Int(viewModel.task.partsUsed.reduce(0) { $0 + $1.totalCost }))")
                            .font(.headline)
                            .foregroundColor(AppTheme.accentPrimary)
                    }
                }
                .padding(.top, 8)
            }
            
            // Labor Cost and Grand Total (always show if labor hours exist)
            if let laborHours = viewModel.task.laborHours, laborHours > 0 {
                VStack(spacing: 8) {
                    if !viewModel.task.partsUsed.isEmpty {
                        Divider()
                            .background(AppTheme.dividerPrimary)
                    }
                    
                    HStack {
                        Text("Labor Cost (\(String(format: "%.1f", laborHours)) hrs @ ₹300/hr)")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Spacer()
                        
                        Text("₹\(Int(laborHours * 300))")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Divider()
                        .background(AppTheme.dividerPrimary)
                    
                    HStack {
                        Text("Grand Total")
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Spacer()
                        
                        Text("₹\(Int(viewModel.task.totalCost))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.accentPrimary)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
    
    // MARK: - Repair Log Card
    
    private func repairLogCard(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            HStack {
                Text("Repair Log")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                if !viewModel.task.isLocked {
                    Button(action: {
                        viewModel.showingEditRepairLogSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.caption)
                            Text("Edit")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(AppTheme.accentPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.backgroundElevated)
                        .cornerRadius(6)
                    }
                }
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            
            if let laborHours = viewModel.task.laborHours {
                InfoRow(icon: "clock.fill", label: "Labor Hours", value: String(format: "%.1f hrs", laborHours))
            }
            
            if !viewModel.task.partsUsed.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Parts Used")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    ForEach(viewModel.task.partsUsed, id: \.partName) { part in
                        HStack {
                            Text("• \(part.partName)")
                                .font(.subheadline)
                            Spacer()
                            Text("₹\(Int(part.totalCost))")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.accentPrimary)
                        }
                    }
                }
            }
        }
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Action Button Component

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(AppTheme.cornerRadius.medium)
        }
    }
}

// MARK: - Completion Sheet

struct CompletionSheet: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var repairDescription: String = ""
    @State private var laborHours: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.spacing.lg) {
                    Text("Complete this task by providing repair details")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                        Text("Repair Description *")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextEditor(text: $repairDescription)
                            .frame(height: 100)
                            .padding(8)
                            .background(AppTheme.backgroundSecondary)
                            .cornerRadius(AppTheme.cornerRadius.small)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                        Text("Labor Hours *")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextField("e.g., 2.5", text: $laborHours)
                            .keyboardType(.decimalPad)
                            .padding(12)
                            .background(AppTheme.backgroundSecondary)
                            .cornerRadius(AppTheme.cornerRadius.small)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if !repairDescription.isEmpty, let hours = Double(laborHours) {
                            Task {
                                await viewModel.completeTask(repairDescription: repairDescription, laborHours: hours)
                                dismiss()
                            }
                        }
                    }) {
                        Text("Mark as Completed")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                (!repairDescription.isEmpty && Double(laborHours) != nil)
                                    ? AppTheme.accentPrimary
                                    : AppTheme.textTertiary
                            )
                            .cornerRadius(AppTheme.cornerRadius.medium)
                    }
                    .disabled(repairDescription.isEmpty || Double(laborHours) == nil)
                }
                .padding(AppTheme.spacing.md)
            }
            .navigationTitle("Complete Task")
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

// MARK: - Failure Sheet

struct FailureSheet: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var failureReason: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.spacing.lg) {
                    Text("Explain why this task failed")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                        Text("Failure Reason *")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        TextEditor(text: $failureReason)
                            .frame(height: 150)
                            .padding(8)
                            .background(AppTheme.backgroundSecondary)
                            .cornerRadius(AppTheme.cornerRadius.small)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if !failureReason.isEmpty {
                            Task {
                                await viewModel.failTask(reason: failureReason)
                                dismiss()
                            }
                        }
                    }) {
                        Text("Mark as Failed")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                !failureReason.isEmpty
                                    ? AppTheme.statusError
                                    : AppTheme.textTertiary
                            )
                            .cornerRadius(AppTheme.cornerRadius.medium)
                    }
                    .disabled(failureReason.isEmpty)
                }
                .padding(AppTheme.spacing.md)
            }
            .navigationTitle("Mark as Failed")
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

// MARK: - Add Part Sheet For Task

struct AddPartSheetForTask: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @StateObject private var inventoryViewModel = InventoryViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory: PartCategory = .engine
    @State private var selectedPart: InventoryPart? = nil
    @State private var quantity: String = "1"
    @State private var isCustomPart: Bool = false
    
    // Custom part fields
    @State private var customPartName: String = ""
    @State private var customUnitPrice: String = ""
    
    var availableParts: [InventoryPart] {
        inventoryViewModel.parts(for: selectedCategory)
    }
    
    var calculatedUnitPrice: Double {
        if isCustomPart {
            return Double(customUnitPrice) ?? 0.0
        } else {
            return selectedPart?.unitPrice ?? 0.0
        }
    }
    
    var calculatedTotalCost: Double {
        guard let qty = Int(quantity) else { return 0.0 }
        return Double(qty) * calculatedUnitPrice
    }
    
    var isValid: Bool {
        if isCustomPart {
            return !customPartName.isEmpty && 
                   Int(quantity) != nil && 
                   Double(customUnitPrice) != nil
        } else {
            return selectedPart != nil && Int(quantity) != nil
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.spacing.lg) {
                        // Toggle between inventory and custom part
                        Picker("Part Source", selection: $isCustomPart) {
                            Text("From Inventory").tag(false)
                            Text("Custom Part").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: isCustomPart) { _ in
                            // Reset fields when switching
                            selectedPart = nil
                            customPartName = ""
                            customUnitPrice = ""
                        }
                        
                        if !isCustomPart {
                            // Inventory Part Selection
                            VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                                Text("Category *")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                Menu {
                                    ForEach(inventoryViewModel.allCategories) { category in
                                        Button(action: {
                                            selectedCategory = category
                                            selectedPart = nil // Reset selection when category changes
                                        }) {
                                            HStack {
                                                Image(systemName: inventoryViewModel.icon(for: category))
                                                Text(inventoryViewModel.displayName(for: category))
                                                if selectedCategory.id == category.id {
                                                    Spacer()
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: inventoryViewModel.icon(for: selectedCategory))
                                            .foregroundColor(AppTheme.accentPrimary)
                                        Text(inventoryViewModel.displayName(for: selectedCategory))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.iconDefault)
                                    }
                                    .padding(12)
                                    .background(AppTheme.backgroundSecondary)
                                    .cornerRadius(AppTheme.cornerRadius.small)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                                Text("Select Part *")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                if availableParts.isEmpty {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(AppTheme.statusWarning)
                                        Text("No parts in this category")
                                            .font(.subheadline)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppTheme.backgroundSecondary)
                                    .cornerRadius(AppTheme.cornerRadius.small)
                                } else {
                                    Menu {
                                        ForEach(availableParts) { part in
                                            Button(action: {
                                                selectedPart = part
                                            }) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    HStack {
                                                        Text(part.name)
                                                        if selectedPart?.id == part.id {
                                                            Spacer()
                                                            Image(systemName: "checkmark")
                                                        }
                                                    }
                                                    Text("\(part.partNumber) • ₹\(String(format: "%.2f", part.unitPrice)) • Stock: \(part.quantityInStock)")
                                                        .font(.caption)
                                                        .foregroundColor(AppTheme.textSecondary)
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            if let part = selectedPart {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(part.name)
                                                        .foregroundColor(AppTheme.textPrimary)
                                                    HStack {
                                                        Text(part.partNumber)
                                                        Text("•")
                                                        Text("₹\(String(format: "%.2f", part.unitPrice))")
                                                        Text("•")
                                                        Text("Stock: \(part.quantityInStock)")
                                                    }
                                                    .font(.caption)
                                                    .foregroundColor(AppTheme.textSecondary)
                                                }
                                            } else {
                                                Text("Select a part")
                                                    .foregroundColor(AppTheme.textSecondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .font(.caption)
                                                .foregroundColor(AppTheme.iconDefault)
                                        }
                                        .padding(12)
                                        .background(AppTheme.backgroundSecondary)
                                        .cornerRadius(AppTheme.cornerRadius.small)
                                    }
                                }
                            }
                            
                            // Show stock warning if low
                            if let part = selectedPart, part.isLowStock {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(AppTheme.statusWarning)
                                    Text("Low stock: only \(part.quantityInStock) available")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.statusWarning)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.statusWarningBackground)
                                .cornerRadius(6)
                            }
                        } else {
                            // Custom Part Entry
                            VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                                Text("Part Name *")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                TextField("e.g., Brake Pads", text: $customPartName)
                                    .padding(12)
                                    .background(AppTheme.backgroundSecondary)
                                    .cornerRadius(AppTheme.cornerRadius.small)
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: AppTheme.spacing.sm) {
                                Text("Unit Price (₹) *")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                TextField("0.00", text: $customUnitPrice)
                                    .keyboardType(.decimalPad)
                                    .padding(12)
                                    .background(AppTheme.backgroundSecondary)
                                    .cornerRadius(AppTheme.cornerRadius.small)
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                        }
                        
                        // Quantity input
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
                        
                        // Cost summary
                        if isValid {
                            VStack(spacing: 12) {
                                Divider()
                                    .background(AppTheme.dividerPrimary)
                                
                                HStack {
                                    Text("Unit Price")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Text("₹\(String(format: "%.2f", calculatedUnitPrice))")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                
                                HStack {
                                    Text("Quantity")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    Spacer()
                                    
                                    Text(quantity)
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                
                                Divider()
                                    .background(AppTheme.dividerPrimary)
                                
                                HStack {
                                    Text("Total Cost")
                                        .font(.headline)
                                        .foregroundColor(AppTheme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text("₹\(String(format: "%.2f", calculatedTotalCost))")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppTheme.accentPrimary)
                                }
                            }
                            .padding(16)
                            .background(AppTheme.backgroundElevated)
                            .cornerRadius(AppTheme.cornerRadius.medium)
                        }
                        
                        Spacer(minLength: 20)
                        
                        // Add button
                        Button(action: addPart) {
                            Text("Add Part")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    isValid
                                        ? AppTheme.accentPrimary
                                        : AppTheme.textTertiary
                                )
                                .cornerRadius(AppTheme.cornerRadius.medium)
                        }
                        .disabled(!isValid)
                    }
                    .padding(AppTheme.spacing.md)
                }
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
            .task {
                await inventoryViewModel.loadInventory()
            }
        }
    }
    
    
    private func addPart() {
        guard let qty = Int(quantity) else { return }
        
        let partName: String
        let partId: UUID?
        
        if isCustomPart {
            partName = customPartName
            partId = nil  // Custom parts don't have inventory ID
        } else if let part = selectedPart {
            partName = part.name
            partId = part.id  // Include inventory part ID for deduction
        } else {
            return
        }
        
        let newPart = PartUsage(
            partId: partId,
            partName: partName,
            quantity: qty,
            unitPrice: calculatedUnitPrice
        )
        
        Task {
            await viewModel.addPart(newPart)
            dismiss()
        }
    }
}

#Preview {
    NavigationView {
        TaskDetailView(
            task: MaintenanceTask(
                vehicleRegistrationNumber: "MH-01-AB-1234",
                priority: .high,
                component: .brakes,
                status: "Pending",
                dueDate: Date(),
                taskType: .emergency,
                description: "Brake pads need immediate replacement"
            )
        )
    }
}
