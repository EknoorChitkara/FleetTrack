//
//  InspectionSummaryView.swift
//  FleetTrack
//
//  Created for Driver
//

import SwiftUI

struct InspectionSummaryView: View {
    let vehicle: Vehicle
    @EnvironmentObject var viewModel: VehicleInspectionViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Assigned Vehicle Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Assigned Vehicle")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 16) {
                        // Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "truck.box.fill") // Placeholder icon based on type
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vehicle.registrationNumber)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("\(vehicle.manufacturer) \(vehicle.model) \(vehicle.yearOfManufacture ?? 2022)")
                                .font(.subheadline)
                                .foregroundColor(.appSecondaryText)
                        }
                        
                        Spacer()
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Vehicle Status")
                                .font(.caption)
                                .foregroundColor(.appSecondaryText)
                            Text("Excellent") // Should derive from vehicle.status or health
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.appEmerald)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Last Service")
                                .font(.caption)
                                .foregroundColor(.appSecondaryText)
                            Text("Dec 28, 2024") // derived from vehicle.lastServiceDate
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
                .background(Color.appCardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Actions")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        // Switch to Checklist tab mechanism needed here or handle in parent
                        // For now just print
                        print("Start Daily Inspection tapped")
                    }) {
                        Text("Start Daily Inspection")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Switch to Booking tab or report issue
                         print("Report Issue tapped")
                    }) {
                        Text("Report Issue")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color.appCardBackground)
                .cornerRadius(16)
            }
            .padding()
        }
    }
}
