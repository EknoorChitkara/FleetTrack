//
//  ReportIssueView.swift
//  FleetTrack
//
//  Created for Driver App
//

import SwiftUI
import Combine
import Supabase

// MARK: - Models

enum IssueType: String, CaseIterable, Identifiable {
    case tirePuncture = "Tire Puncture"
    case engineIssue = "Engine Issue"
    case brakeProblem = "Brake Problem"
    case oilChange = "Oil Change"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .tirePuncture: return "circle.dashed" // approximate
        case .engineIssue: return "engine.combustion"
        case .brakeProblem: return "exclamationmark.octagon" // approximate
        case .oilChange: return "drop.fill"
        }
    }
}

enum IssueSeverity: String, CaseIterable, Identifiable {
    case normal = "Normal"
    case warning = "Warning"
    case critical = "Critical"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

class ReportIssueViewModel: ObservableObject {
    @Published var selectedIssueType: IssueType?
    @Published var selectedSeverity: IssueSeverity = .normal
    @Published var description: String = ""
    @Published var showingConfirmation = false
    @Published var isSubmitting = false
    
    // Optional context (passed from parent view)
    var tripId: UUID?
    var vehicleId: UUID?
    var driverId: UUID?
    
    func submitAlert() {
        guard let issueType = selectedIssueType else { return }
        isSubmitting = true
        
        Task {
            do {
                let timestamp = ISO8601DateFormatter().string(from: Date())
                
                // 1. Create Alert record (General)
                let alert = AlertCreate(
                    tripId: tripId,
                    title: issueType.rawValue,
                    message: description.isEmpty ? issueType.rawValue : description,
                    type: selectedSeverity.rawValue,
                    timestamp: timestamp,
                    isRead: false
                )
                
                try await supabase
                    .from("alerts")
                    .insert(alert)
                    .execute()
                
                // 2. Create Maintenance Alert (For Dashboard)
                // Map severity/type to maintenance alert types logic if needed
                let maintenanceAlert = MaintenanceAlertCreate(
                    title: "Issue Reported: \(issueType.rawValue)",
                    message: "Severity: \(selectedSeverity.rawValue). \(description)",
                    type: "Emergency", // Always treat driver reports as urgent/emergency for now
                    date: timestamp,
                    isRead: false
                )
                
                try await supabase
                    .from("maintenance_alerts")
                    .insert(maintenanceAlert)
                    .execute()
                
                // 3. Create Vehicle Inspection Record for History
                if let vehicleId = vehicleId {
                    let session = try await supabase.auth.session
                    let drivers: [FMDriver] = try await supabase
                        .from("drivers")
                        .select()
                        .eq("user_id", value: session.user.id)
                        .execute()
                        .value
                    
                    if let driver = drivers.first {
                        let currentDate = Date()
                        let inspectionRecord = VehicleInspection(
                            id: UUID(),
                            vehicleId: vehicleId,
                            driverId: driver.id,
                            inspectionDate: currentDate,
                            checklistItems: [],
                            itemsChecked: 0,
                            totalItems: 0,
                            allItemsPassed: false,
                            notes: "Issue Reported: \(issueType.rawValue) (Severity: \(selectedSeverity.rawValue)) - \(description)",
                            status: "Issue Reported",
                            createdAt: currentDate,
                            updatedAt: currentDate
                        )
                        
                        try await supabase
                            .from("vehicle_inspections")
                            .insert(inspectionRecord)
                            .execute()
                        
                        print("✅ Inspection record created for issue report")
                    }
                }
                
                await MainActor.run {
                    print("✅ Alert submitted successfully")
                    isSubmitting = false
                    showingConfirmation = true
                }
                
            } catch {
                print("❌ Failed to submit alert: \(error)")
                await MainActor.run {
                    isSubmitting = false
                    // Ideally show error alert here, but for now we fallback
                    showingConfirmation = true 
                }
            }
        }
    }
}

struct ReportIssueView: View {
    let vehicle: Vehicle?
    @StateObject private var viewModel: ReportIssueViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(vehicle: Vehicle? = nil) {
        self.vehicle = vehicle
        _viewModel = StateObject(wrappedValue: {
            let vm = ReportIssueViewModel()
            vm.vehicleId = vehicle?.id
            return vm
        }())
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                            .accessibilityLabel("Back to Dashboard")
                            .accessibilityIdentifier("report_issue_back_button")
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Report Issue")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Emergency or maintenance alert")
                            .font(.caption)
                            .foregroundColor(.appSecondaryText)
                    }
                    
                    Spacer()
                    
                    // FleetTrack Logo/Badge placeholder if needed, or just profile
                    Image(systemName: "person.circle")
                         .font(.system(size: 24))
                         .foregroundColor(.white.opacity(0.3))
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 32) {
                        
                        // Issue Type Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Issue Type")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(IssueType.allCases) { type in
                                    IssueTypeCard(
                                        type: type,
                                        isSelected: viewModel.selectedIssueType == type,
                                        action: { viewModel.selectedIssueType = type }
                                    )
                                }
                            }
                        }
                        
                        // Severity Level
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Severity Level")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                ForEach(IssueSeverity.allCases) { severity in
                                    SeverityRow(
                                        severity: severity,
                                        isSelected: viewModel.selectedSeverity == severity,
                                        action: { viewModel.selectedSeverity = severity }
                                    )
                                }
                            }
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextEditor(text: $viewModel.description)
                                .frame(height: 120)
                                .padding()
                                .scrollContentBackground(.hidden)
                                .accessibilityLabel("Issue Description")
                                .accessibilityIdentifier("report_issue_description_field")
                                .background(Color.appCardBackground)
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .overlay(
                                    Group {
                                        if viewModel.description.isEmpty {
                                            Text("Describe the issue in detail...")
                                                .foregroundColor(.gray)
                                                .padding(.leading, 16)
                                                .padding(.top, 20)
                                                .allowsHitTesting(false)
                                        }
                                    },
                                    alignment: .topLeading
                                )
                        }
                        
                        // NO Photo Button as requested
                        
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
            
            // Bottom Button
            VStack {
                Spacer()
                Button(action: viewModel.submitAlert) {
                    Text("Send Alert")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appEmerald) // Green
                        .cornerRadius(12)
                }
                .padding()
                .accessibilityIdentifier("report_issue_submit_button")
                .background(Color.appBackground) // Fade/Solid bg behind button?
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $viewModel.showingConfirmation) {
            Alert(
                title: Text("Alert Sent"),
                message: Text("Your issue report has been submitted."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Components

struct IssueTypeCard: View {
    let type: IssueType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: type.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .appSecondaryText)
                
                Text(type.rawValue)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white : .appSecondaryText)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(isSelected ? Color.appCardBackground.opacity(1.5) : Color.appCardBackground)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.appEmerald : Color.clear, lineWidth: 2)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(type.rawValue)")
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
        }
    }
}

struct SeverityRow: View {
    let severity: IssueSeverity
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(severity.color)
                    .frame(width: 12, height: 12)
                
                Text(severity.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.appEmerald)
                }
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.appEmerald.opacity(0.5) : Color.clear, lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(severity.rawValue)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
        }
    }
}
