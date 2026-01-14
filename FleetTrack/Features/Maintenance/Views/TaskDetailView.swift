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
        .sheet(isPresented: $viewModel.showingEditRepairLogSheet) {
            EditRepairLogSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingAddPartSheet) {
            AddPartSheetForTask(viewModel: viewModel)
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
            StatusBadge(status: viewModel.task.status)
            
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
                            viewModel.showingCompletionSheet = true
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
                
                if viewModel.task.status == "Completed" || viewModel.task.status == "Failed" {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                        Text("Task is locked and cannot be modified")
                            .font(.caption)
                    }
                    .foregroundColor(AppTheme.textTertiary)
                    .padding(.vertical, 8)
                }
            }
        }
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
            
            InfoRow(icon: "car.fill", label: "Registration", value: viewModel.task.vehicleRegistrationNumber)
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
            
            // Mock driver info - in real app, fetch from database using assignedDriverId
            let driverName = "Rajesh Kumar"
            let driverPhone = "+91 98765 43210"
            
            VStack(spacing: AppTheme.spacing.sm) {
                InfoRow(icon: "person.fill", label: "Driver", value: driverName)
                InfoRow(icon: "phone.fill", label: "Phone", value: driverPhone)
                
                // Call Button
                Button(action: {
                    if let url = URL(string: "tel://\(driverPhone.replacingOccurrences(of: " ", with: ""))") {
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
                
                // Cost Summary
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
                    
                    if let laborHours = viewModel.task.laborHours {
                        HStack {
                            Text("Labor Cost (\(String(format: "%.1f", laborHours)) hrs @ ₹500/hr)")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Spacer()
                            
                            Text("₹\(Int(laborHours * 500))")
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
                            Task {
                                await viewModel.addPart(newPart)
                                dismiss()
                            }
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
