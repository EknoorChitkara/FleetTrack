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
    @State private var showRegistrationError = false
    @State private var showDuplicateAlert = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case registration
    }
    
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
                        if fleetVM.isVehicleRegistered(formData.registrationNumber) {
                            withAnimation(.spring()) {
                                showDuplicateAlert = true
                            }
                            // Auto-hide alert after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    showDuplicateAlert = false
                                }
                            }
                        } else {
                            fleetVM.addVehicle(formData)
                            presentationMode.wrappedValue.dismiss()
                        }
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
                            VStack(spacing: 8) {
                                ModernTextField(icon: "number.square.fill", placeholder: "Registration Number (e.g., XX-00-XX0000)", text: $formData.registrationNumber, isRequired: true)
                                    .focused($focusedField, equals: .registration)
                                
                                if showRegistrationError && !isValidRegistration {
                                    Text("Invalid format. Expected: XX-00-XX0000")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 52) // Align with text inside field (16 padding + 24 icon + 12 spacing)
                                }
                            }
                            
                            ModernDriverPicker(icon: "person.fill.badge.plus", selection: $formData.assignedDriverId, drivers: fleetVM.unassignedDrivers, placeholder: "Assign Driver")
                                .simultaneousGesture(TapGesture().onEnded { validateRegistrationOnInteraction() })
                                .onChange(of: formData.assignedDriverId) { _ in validateRegistrationOnInteraction() }
                            
                            HStack(spacing: 16) {
                                ModernPicker(icon: "car.fill", title: "Type", selection: $formData.vehicleType, options: vehicleTypes)
                                    .frame(maxWidth: .infinity)
                                    .simultaneousGesture(TapGesture().onEnded { validateRegistrationOnInteraction() })
                                    .onChange(of: formData.vehicleType) { _ in validateRegistrationOnInteraction() }
                                ModernTextField(icon: "building.2.fill", placeholder: "Manufacturer", text: $formData.manufacturer, isRequired: true)
                                    .frame(maxWidth: .infinity)
                                    .onTapGesture { validateRegistrationOnInteraction() }
                            }
                            
                            HStack(spacing: 16) {
                                ModernTextField(icon: "info.circle.fill", placeholder: "Model", text: $formData.model, isRequired: true)
                                    .frame(maxWidth: .infinity)
                                    .onTapGesture { validateRegistrationOnInteraction() }
                                ModernPicker(icon: "fuelpump.fill", title: "Fuel", selection: $formData.fuelType, options: fuelTypes)
                                    .frame(maxWidth: .infinity)
                                    .simultaneousGesture(TapGesture().onEnded { validateRegistrationOnInteraction() })
                                    .onChange(of: formData.fuelType) { _ in validateRegistrationOnInteraction() }
                            }
                            
                            HStack(spacing: 16) {
                                ModernTextField(icon: "scalemass.fill", placeholder: "Capacity", text: $formData.capacity, isRequired: true)
                                    .frame(maxWidth: .infinity)
                                    .onTapGesture { validateRegistrationOnInteraction() }
                                ModernDatePicker(icon: "calendar", title: "Reg Date", selection: $formData.registrationDate, throughDate: Date())
                                    .frame(maxWidth: .infinity)
                                    .simultaneousGesture(TapGesture().onEnded { validateRegistrationOnInteraction() })
                                    .onChange(of: formData.registrationDate) { _ in validateRegistrationOnInteraction() }
                            }
                            
                            ModernPicker(icon: "checkmark.circle.fill", title: "Status", selection: $formData.status, options: statuses)
                                .simultaneousGesture(TapGesture().onEnded { validateRegistrationOnInteraction() })
                                .onChange(of: formData.status) { _ in validateRegistrationOnInteraction() }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            
            // Duplicate Alert Popup
            if showDuplicateAlert {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        Text("Vehicle with this registration already exists!")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {
                            withAnimation {
                                showDuplicateAlert = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    .padding(.top, 60) // Positioned below the header area
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .onChange(of: focusedField) { newValue in
            if newValue != .registration && !formData.registrationNumber.isEmpty {
                showRegistrationError = true
            }
        }
        .onChange(of: formData.registrationNumber) { _ in
            if showDuplicateAlert {
                withAnimation {
                    showDuplicateAlert = false
                }
            }
        }
    }
    
    private func validateRegistrationOnInteraction() {
        if !formData.registrationNumber.isEmpty && !isValidRegistration {
            showRegistrationError = true
        }
    }
    
    private var isValidRegistration: Bool {
        let regEx = "^[A-Z]{2}-\\d{2}-[A-Z]{1,2}\\d{4}$"
        let pred = NSPredicate(format:"SELF MATCHES %@", regEx)
        return pred.evaluate(with: formData.registrationNumber.uppercased())
    }
}
