//
//  VehicleDetailView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct VehicleDetailView: View {
    let vehicle: FMVehicle
    @Environment(\.presentationMode) var presentationMode
    @State private var showInspection = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vehicle.registrationNumber)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        HStack(spacing: 6) {
                            Text(vehicle.model)
                            Circle().frame(width: 4, height: 4)
                            HStack(spacing: 4) {
                                Circle().frame(width: 8, height: 8).foregroundColor(.green)
                                Text(vehicle.status.rawValue)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Quick Actions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Actions")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 16) {
                                QuickActionBtn(title: "Inspection", icon: "doc.text.fill", color: .blue) {
                                    showInspection = true
                                }
                                QuickActionBtn(title: "Assign", icon: "person.badge.plus.fill", color: .green) {
                                    // Assign logic
                                }
                                QuickActionBtn(title: "Service", icon: "wrench.and.screwdriver.fill", color: .orange) {
                                    // Service logic
                                }
                            }
                        }
                        .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Vehicle Information")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 0) {
                                InfoRow(icon: "car.fill", label: "Model", value: vehicle.model)
                                Divider().background(Color.gray.opacity(0.2))
                                InfoRow(icon: "number", label: "License Plate", value: vehicle.registrationNumber)
                                Divider().background(Color.gray.opacity(0.2))
                                InfoRow(icon: "fingerprint", label: "VIN", value: vehicle.vin ?? "N/A")
                                Divider().background(Color.gray.opacity(0.2))
                                InfoRow(icon: "speedometer", label: "Mileage", value: formatMileage(vehicle.mileage))
                                Divider().background(Color.gray.opacity(0.2))
                                InfoRow(icon: "shield.fill", label: "Insurance", value: vehicle.insuranceStatus ?? "Pending")
                            }
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                            
                            Text("Current Status")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 10)
                            
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Fuel Level")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text("100%")
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    ProgressView(value: 1.0)
                                        .tint(.green)
                                        .frame(width: 100)
                                }
                                
                                Divider().background(Color.gray.opacity(0.2))
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Assigned Driver")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(vehicle.assignedDriverName ?? "Unassigned")
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    if vehicle.assignedDriverId != nil {
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.appEmerald)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showInspection) {
            VehicleInspectionView(vehicle: vehicle)
        }
    }
    
    private func formatMileage(_ mileage: Double?) -> String {
        guard let mileage = mileage else { return "0 km" }
        return String(format: "%.0f km", mileage)
    }
    
    @EnvironmentObject var fleetVM: FleetViewModel
}

struct QuickActionBtn: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(16)
                    .background(color.opacity(0.2))
                    .cornerRadius(12)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            
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
