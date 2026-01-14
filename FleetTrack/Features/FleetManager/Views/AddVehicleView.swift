//
//  AddVehicleView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct AddVehicleView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fleetVM: FleetViewModel
    @State private var formData = VehicleCreationData()
    @State private var showError = false
    
    // Mock data for dropdowns
    let vehicleTypes = VehicleType.allCases
    let fuelTypes = FuelType.allCases
    let statuses = VehicleStatus.allCases
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Navigation items replacement since we want custom UI)
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("Add Vehicle")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        fleetVM.addVehicle(formData)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Save")
                            .fontWeight(.bold)
                            .foregroundColor(!isValidRegistration ? .gray : .appEmerald)
                    }
                    .disabled(!isValidRegistration)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        ModernFormHeader(
                            title: "Vehicle Registration",
                            subtitle: "Enter the details of the new vehicle",
                            iconName: "truck.box.fill"
                        )
                        
                        VStack(spacing: 16) {
                            ModernTextField(icon: "number.square.fill", placeholder: "Registration Number (e.g., MH-14-AB1234)", text: $formData.registrationNumber, isRequired: true)
                            
                            ModernDriverPicker(icon: "person.fill.badge.plus", selection: $formData.assignedDriverId, drivers: fleetVM.unassignedDrivers, placeholder: "Assign Driver")
                            
                            HStack(spacing: 16) {
                                ModernPicker(icon: "car.fill", title: "Type", selection: $formData.vehicleType, options: vehicleTypes)
                                    .frame(maxWidth: .infinity)
                                ModernTextField(icon: "building.2.fill", placeholder: "Manufacturer", text: $formData.manufacturer, isRequired: true)
                                    .frame(maxWidth: .infinity)
                            }
                            
                            HStack(spacing: 16) {
                                ModernTextField(icon: "info.circle.fill", placeholder: "Model", text: $formData.model, isRequired: true)
                                    .frame(maxWidth: .infinity)
                                ModernPicker(icon: "fuelpump.fill", title: "Fuel", selection: $formData.fuelType, options: fuelTypes)
                                    .frame(maxWidth: .infinity)
                            }
                            
                            HStack(spacing: 16) {
                                ModernTextField(icon: "scalemass.fill", placeholder: "Capacity", text: $formData.capacity, isRequired: true)
                                    .frame(maxWidth: .infinity)
                                ModernDatePicker(icon: "calendar", title: "Reg Date", selection: $formData.registrationDate, throughDate: Date())
                                    .frame(maxWidth: .infinity)
                            }
                            
                            ModernPicker(icon: "checkmark.circle.fill", title: "Status", selection: $formData.status, options: statuses)
                        }
                        .padding(.horizontal)
                        
                        if !formData.registrationNumber.isEmpty && !isValidRegistration {
                            Text("Invalid format. Expected: MH-14-AB1234")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
    }
    
    private var isValidRegistration: Bool {
        let regEx = "^[A-Z]{2}-\\d{2}-[A-Z]{1,2}\\d{4}$"
        let pred = NSPredicate(format:"SELF MATCHES %@", regEx)
        return pred.evaluate(with: formData.registrationNumber.uppercased())
    }
}
