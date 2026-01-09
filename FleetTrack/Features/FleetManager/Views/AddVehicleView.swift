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
    
    // Mock data for dropdowns
    let vehicleTypes = VehicleType.allCases
    let fuelTypes = FuelType.allCases
    let statuses = VehicleStatus.allCases
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        HStack {
                            Image(systemName: "truck.box.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.appEmerald)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Add New Vehicle")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Register a new vehicle to your fleet")
                                    .font(.subheadline)
                                    .foregroundColor(.appSecondaryText)
                            }
                        }
                        .padding(.top)
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            Group {
                                CustomTextField(title: "Vehicle Number", placeholder: "e.g., MH-14-AB1234", text: $formData.registrationNumber, isRequired: true)
                                    .padding(.bottom, 16)
                                
                                CustomDropdown(title: "Assign Driver", selection: $formData.assignedDriverId, drivers: fleetVM.drivers, placeholder: "Unassigned")
                                    .padding(.bottom, 16)
                                
                                HStack(spacing: 16) {
                                    CustomPicker(title: "Vehicle Type", selection: $formData.vehicleType, options: vehicleTypes)
                                    CustomTextField(title: "Manufacturer", placeholder: "e.g., Toyota", text: $formData.manufacturer, isRequired: true)
                                }
                                
                                HStack(spacing: 16) {
                                    CustomTextField(title: "Vehicle Model", placeholder: "e.g., Camry", text: $formData.model, isRequired: true)
                                    CustomPicker(title: "Fuel Type", selection: $formData.fuelType, options: fuelTypes)
                                }
                                
                                HStack(spacing: 16) {
                                    CustomTextField(title: "Capacity", placeholder: "e.g., 5", text: $formData.capacity, isRequired: true)
                                    CustomDatePicker(title: "Registration Date", selection: $formData.registrationDate)
                                }
                                
                                CustomPicker(title: "Vehicle Status", selection: $formData.status, options: statuses)
                            }
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(16)
                        
                        Spacer(minLength: 20)
                        
                        // Action Buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Cancel")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(white: 0.2))
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                fleetVM.addVehicle(formData)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Add Vehicle")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(formData.registrationNumber.isEmpty ? Color.gray : Color.appEmerald)
                                    .cornerRadius(12)
                            }
                            .disabled(formData.registrationNumber.isEmpty)
                        }
                        
                        Text("* Indicates required field")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Reusable Form Components

struct CustomTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isRequired: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                }
            }
            
            TextField(placeholder, text: $text)
                .padding()
                .background(Color.appBackground) // Darker background for input
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(white: 0.2), lineWidth: 1)
                )
                .foregroundColor(.white)
        }
    }
}

// Simplified Dropdown for Mock (String based for Driver Name demo)
struct CustomDropdown: View {
    let title: String
    @Binding var selection: UUID?
    let drivers: [FMDriver]
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                Text("*")
                    .foregroundColor(.red)
            }
            
            Menu {
                Button(action: {
                    selection = nil
                }) {
                    Text("Unassigned")
                }
                
                ForEach(drivers) { driver in
                    Button(action: {
                        selection = driver.id
                    }) {
                        Text(driver.fullName)
                    }
                }
            } label: {
                HStack {
                    Text(selection == nil ? "Unassigned" : (drivers.first(where: { $0.id == selection })?.fullName ?? placeholder))
                        .foregroundColor(selection == nil ? .gray : .white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.appBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(white: 0.2), lineWidth: 1)
                )
            }
        }
    }
}

struct CustomPicker<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let title: String
    @Binding var selection: T
    let options: [T]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                Text("*")
                    .foregroundColor(.red)
            }
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selection = option
                    }) {
                        Text(option.rawValue)
                    }
                }
            } label: {
                HStack {
                    Text(selection.rawValue)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.appBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(white: 0.2), lineWidth: 1)
                )
            }
        }
    }
}

struct CustomDatePicker: View {
    let title: String
    @Binding var selection: Date
    var maxDate: Date = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                Text("*")
                    .foregroundColor(.red)
            }
            
            HStack {
                Text(selection, style: .date)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.appBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(white: 0.2), lineWidth: 1)
            )
            .overlay(
                DatePicker("", selection: $selection, in: ...maxDate, displayedComponents: .date)
                    .labelsHidden()
                    .opacity(0.011)
            )
        }
    }
}
