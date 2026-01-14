//
//  InspectionHistoryView.swift
//  FleetTrack
//
//  Created for Driver
//

import SwiftUI

struct InspectionHistoryView: View {
    @EnvironmentObject var viewModel: VehicleInspectionViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.maintenanceHistory) { record in
                    MaintenanceHistoryRow(record: record)
                }
            }
            .padding()
        }
    }
}

struct MaintenanceHistoryRow: View {
    let record: MaintenanceRecord
    
    var statusColor: Color {
        switch record.status {
        case .completed: return .appEmerald
        case .inProgress: return .orange
        case .scheduled: return .blue
        case .cancelled: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(record.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Date logic placeholder
                Text("Dec 28, 2024")
                    .font(.caption)
                    .foregroundColor(.appSecondaryText)
            }
            
            HStack {
                Text(record.status.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
                
                Spacer()
            }
            
            if let description = record.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}
