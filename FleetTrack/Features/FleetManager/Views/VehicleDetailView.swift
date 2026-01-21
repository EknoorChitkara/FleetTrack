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
    @State private var showServiceSelection = false
    @State private var showHistory = false
    @State private var selectedServices: Set<String> = []
    @State private var serviceDescription: String = ""
    @State private var showRetireAlert = false
    @State private var showAssignmentSuccess = false
    
    private var currentVehicle: FMVehicle {
        fleetVM.vehicles.first(where: { $0.id == vehicle.id }) ?? vehicle
    }
    
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
                    .accessibilityLabel("Back")
                    .accessibilityIdentifier("vehicle_detail_back_button")
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentVehicle.registrationNumber)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        HStack(spacing: 6) {
                            Text(currentVehicle.model)
                            Circle().frame(width: 4, height: 4)
                            HStack(spacing: 4) {
                                Circle().frame(width: 8, height: 8).foregroundColor(statusColor(currentVehicle.status))
                                Text(currentVehicle.status.rawValue)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding(.leading, 8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Vehicle \(currentVehicle.registrationNumber), \(currentVehicle.model), Status \(currentVehicle.status.rawValue)")
                    .accessibilityIdentifier("vehicle_header_info")
                    
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
                                
                                Menu {
                                    // Show unassign option only if vehicle has an assigned driver
                                    if currentVehicle.assignedDriverId != nil {
                                        Button(action: {
                                            fleetVM.reassignDriver(vehicleId: vehicle.id, driverId: nil)
                                        }) {
                                            Label("Unassign Driver", systemImage: "person.fill.xmark")
                                        }
                                        
                                        if !fleetVM.unassignedDrivers.isEmpty {
                                            Divider()
                                        }
                                    }
                                    
                                    // Show available drivers
                                    ForEach(fleetVM.unassignedDrivers) { driver in
                                        Button(action: {
                                            fleetVM.reassignDriver(vehicleId: vehicle.id, driverId: driver.id)
                                            // Frontend confirmation simulation
                                            showAssignmentSuccess = true
                                        }) {
                                            Label(driver.displayName, systemImage: "person.fill")
                                        }
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: "person.badge.plus.fill")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                            .padding(16)
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(12)
                                        
                                        Text("Assign")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(16)
                                }
                                .disabled(fleetVM.unassignedDrivers.isEmpty && currentVehicle.assignedDriverId == nil)
                                .accessibilityLabel("Assign Driver")
                                .accessibilityHint("Double tap to assign or unassign a driver to this vehicle")
                                .accessibilityIdentifier("vehicle_assign_button")
                                
                                QuickActionBtn(title: "Service", icon: "wrench.and.screwdriver.fill", color: .orange) {
                                    selectedServices = Set(vehicle.maintenanceServices ?? [])
                                    serviceDescription = vehicle.maintenanceDescription ?? ""
                                    showServiceSelection = true
                                }
                                
                                QuickActionBtn(title: "History", icon: "clock.arrow.circlepath", color: .purple) {
                                    showHistory = true
                                }
                                
                                QuickActionBtn(title: "Retire", icon: "archivebox.fill", color: .red) {
                                    showRetireAlert = true
                                }
                            }
                        }
                        .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Vehicle Information")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 0) {
                                InfoRow(icon: "car.fill", label: "Model", value: currentVehicle.model)
                                Divider().background(Color.gray.opacity(0.2))
                                InfoRow(icon: "number", label: "License Plate", value: currentVehicle.registrationNumber)
                                Divider().background(Color.gray.opacity(0.2))
                                InfoRow(icon: "speedometer", label: "Mileage", value: formatMileage(currentVehicle.mileage))
                                Divider().background(Color.gray.opacity(0.2))
                                InfoRow(icon: "shield.fill", label: "Insurance", value: currentVehicle.insuranceStatus ?? "Pending")
                            }
                            .background(Color.appCardBackground)
                            .cornerRadius(12)
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("Vehicle Information")
                            .accessibilityIdentifier("vehicle_info_section")
                            
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
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("Current Status")
                            .accessibilityIdentifier("vehicle_status_section")
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showInspection) {
            VehicleInspectionView(vehicle: currentVehicle)
        }
        .sheet(isPresented: $showServiceSelection) {
            ServiceSelectionView(vehicle: currentVehicle, selectedServices: $selectedServices, description: $serviceDescription) {
                fleetVM.markForService(vehicleId: currentVehicle.id, serviceTypes: Array(selectedServices), description: serviceDescription)
                serviceDescription = "" // Reset for next time
                presentationMode.wrappedValue.dismiss()
            }
            .environmentObject(fleetVM)
        }
        .sheet(isPresented: $showHistory) {
            MaintenanceHistoryView(vehicle: currentVehicle)
        }
        .alert("Retire Vehicle", isPresented: $showRetireAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Retire", role: .destructive) {
                fleetVM.retireVehicle(byId: vehicle.id)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to retire this vehicle? This will unassign any active driver and move the vehicle to the retired archive.")
        }
        .alert("Success", isPresented: $showAssignmentSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Driver assigned successfully to vehicle \(vehicle.registrationNumber).")
        }
    }
    
    private func formatMileage(_ mileage: Double?) -> String {
        guard let mileage = mileage else { return "0 km" }
        return String(format: "%.0f km", mileage)
    }
    
    @EnvironmentObject var fleetVM: FleetViewModel
    
    private func statusColor(_ status: VehicleStatus) -> Color {
        switch status {
        case .active: return .green
        case .inactive: return .red
        case .inMaintenance: return .yellow
        case .retired: return .gray
        }
    }
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
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to perform \(title) action")
        .accessibilityIdentifier("quick_action_\(title.lowercased())")
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
        .accessibilityIdentifier("info_row_\(label.lowercased().replacingOccurrences(of: " ", with: "_"))")
    }
}

struct ServiceSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    let vehicle: FMVehicle
    @Binding var selectedServices: Set<String>
    @Binding var description: String
    let onSave: () -> Void
    
    private var isReadOnly: Bool {
        vehicle.status == .inMaintenance
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.gray)
                    .accessibilityLabel("Cancel")
                    .accessibilityIdentifier("service_selection_cancel_button")
                    
                    Spacer()
                    
                    Text("Select Services")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if isReadOnly {
                        Button("Close") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                    } else {
                        Button("Save") {
                            onSave()
                        }
                        .foregroundColor(selectedServices.isEmpty ? .gray : .appEmerald)
                        .fontWeight(.bold)
                        .disabled(selectedServices.isEmpty)
                        .accessibilityLabel("Save")
                        .accessibilityIdentifier("service_selection_save_button")
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ModernFormHeader(title: "Maintenance", subtitle: "Select all components that need work", iconName: "wrench.and.screwdriver.fill")
                        
                        if let lastService = vehicle.lastService {
                            HStack {
                                Spacer()
                                Text("Last Service: \(lastService.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                Spacer()
                            }
                            .padding(.top, -10)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            ModernTextField(icon: "pencil.and.outline", placeholder: "What is the problem in the vehicle?", text: $description)
                                .padding(.horizontal)
                                .disabled(isReadOnly)
                                .opacity(isReadOnly ? 0.6 : 1.0)
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(FleetViewModel.maintenanceOptions, id: \.self) { service in
                                Button(action: {
                                    guard !isReadOnly else { return }
                                    if selectedServices.contains(service) {
                                        selectedServices.remove(service)
                                    } else {
                                        selectedServices.insert(service)
                                    }
                                }) {
                                    HStack {
                                        Text(service)
                                            .foregroundColor(.white)
                                        Spacer()
                                        if selectedServices.contains(service) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.appEmerald)
                                        } else {
                                            Circle()
                                                .stroke(Color.gray, lineWidth: 1)
                                                .frame(width: 22, height: 22)
                                        }
                                    }
                                    .padding()
                                    .background(Color.appCardBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedServices.contains(service) ? Color.appEmerald.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
                                    )
                                }
                                .accessibilityLabel(service)
                                .accessibilityAddTraits(selectedServices.contains(service) ? [.isSelected] : [])
                                .accessibilityIdentifier("service_option_\(service.lowercased().replacingOccurrences(of: " ", with: "_"))")
                            }
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
    }

