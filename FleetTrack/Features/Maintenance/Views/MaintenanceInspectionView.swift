//
//  MaintenanceInspectionView.swift
//  FleetTrack
//
//  Created for Maintenance Module
//

import SwiftUI
import Supabase
import Combine

struct MaintenanceInspectionView: View {
    @StateObject private var viewModel = MaintenanceInspectionViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(12)
                            .background(AppTheme.backgroundSecondary)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Back")
                    .accessibilityIdentifier("maintenance_inspection_back_button")
                    
                    Text("Daily Inspections")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                }
                .padding()
                
                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(AppTheme.accentPrimary)
                    Spacer()
                } else if viewModel.inspections.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checklist")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.textTertiary)
                        Text("No inspections found")
                            .font(.headline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.inspections) { inspection in
                                MaintenanceInspectionRow(inspection: inspection)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.fetchInspections()
                    }
                }
            }
        }
        .onAppear {
            Task { await viewModel.fetchInspections() }
        }
    }
}

struct MaintenanceInspectionRow: View {
    let inspection: VehicleInspection
    
    var statusColor: Color {
        switch inspection.status {
        case "Passed": return AppTheme.statusActiveText
        case "Failed": return AppTheme.statusError
        case "Needs Review": return AppTheme.statusWarning
        default: return AppTheme.textSecondary
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(inspection.inspectionDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
                
                Text(inspection.status)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
            }
            
            // We should ideally fetch vehicle registration here or join it in the query.
            // For now displaying ID or simple text
            Text("Vehicle ID: \(inspection.vehicleId.uuidString.prefix(8))...")
                 .font(.headline)
                 .foregroundColor(AppTheme.textPrimary)
            
            if let notes = inspection.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(AppTheme.backgroundSecondary)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(inspection.status) Inspection for Vehicle \(inspection.vehicleId.uuidString.prefix(4)). \(inspection.inspectionDate.formatted(date: .abbreviated, time: .shortened)). \(inspection.notes ?? "")")
        .accessibilityHint(inspection.status == "Failed" ? "High priority" : "")
        .accessibilityIdentifier("maintenance_inspection_row_\(inspection.id.uuidString.prefix(8))")
    }
}

class MaintenanceInspectionViewModel: ObservableObject {
    @Published var inspections: [VehicleInspection] = []
    @Published var isLoading = false
    
    func fetchInspections() async {
        await MainActor.run { isLoading = true }
        
        do {
            let fetched: [VehicleInspection] = try await SupabaseClientManager.shared.client
                .from("vehicle_inspections")
                .select()
                .order("inspection_date", ascending: false)
                .limit(50)
                .execute()
                .value
            
            await MainActor.run {
                self.inspections = fetched
                self.isLoading = false
            }
        } catch {
            print("❌ Failed to fetch inspections: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
}
