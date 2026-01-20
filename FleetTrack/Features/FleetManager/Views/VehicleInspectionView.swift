//
//  VehicleInspectionView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct VehicleInspectionView: View {
    let vehicle: FMVehicle
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header with Done button
                    HStack {
                        Spacer()
                        Text("Inspection Info")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Text(vehicle.registrationNumber)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Inspection Sheet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Info Table
                            VStack(spacing: 0) {
                                InspectionRow(label: "Registration", value: vehicle.registrationNumber)
                                Divider().background(Color.gray.opacity(0.2))
                                InspectionRow(label: "Manufacturer", value: vehicle.manufacturer)
                                Divider().background(Color.gray.opacity(0.2))
                                InspectionRow(label: "Model", value: vehicle.model)
                                Divider().background(Color.gray.opacity(0.2))
                                InspectionRow(label: "Fuel Type", value: vehicle.fuelType.rawValue)
                                Divider().background(Color.gray.opacity(0.2))
                                InspectionRow(label: "Capacity", value: vehicle.capacity)
                                Divider().background(Color.gray.opacity(0.2))
                                InspectionRow(label: "Registration Date", value: formatDate(vehicle.registrationDate))
                            }
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                            
                            // Status Section
                            VStack(spacing: 0) {
                                InspectionRow(label: "Current Status", value: vehicle.status.rawValue)
                                Divider().background(Color.gray.opacity(0.2))
                                InspectionRow(label: "Last Service", value: formatOptionalDate(vehicle.lastService))
                            }
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    private func formatOptionalDate(_ date: Date?) -> String {
        guard let date = date else { return "Never" }
        return formatDate(date)
    }
    
    private func formatMileage(_ mileage: Double?) -> String {
        guard let mileage = mileage else { return "0 km" }
        return String(format: "%.0f km", mileage)
    }
}

struct InspectionRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding()
    }
}
