//
//  AddVehicleView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI
import UIKit

struct AddVehicleView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fleetVM: FleetViewModel
    @State private var formData = VehicleCreationData()
    @State private var showError = false
    @State private var showRegistrationError = false
    @State private var showDuplicateAlert = false
    @State private var showSaveConfirmation = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case registration, manufacturer, model, capacity
    }
    
    // Mock data for dropdowns
    let vehicleTypes: [VehicleType] = [.truck, .van, .car, .other]
    let fuelTypes = FuelType.allCases
    
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
                    .accessibilityLabel("Cancel")
                    .accessibilityIdentifier("add_vehicle_cancel_button")
                    Spacer()
                    Text("Add Vehicle")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        if fleetVM.isVehicleRegistered(formData.registrationNumber) {
                            withAnimation(.spring()) {
                                showDuplicateAlert = true
                                UIAccessibility.post(notification: .announcement, argument: "Error: Vehicle with this registration already exists")
                            }
                            // Auto-hide alert after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    showDuplicateAlert = false
                                }
                            }
                        } else {
                            showSaveConfirmation = true
                        }
                    }) {
                        Text("Save")
                            .fontWeight(.bold)
                            .foregroundColor(!isFormValid ? .gray : .appEmerald)
                    }
                    .disabled(!isFormValid)
                    .accessibilityLabel("Save")
                    .accessibilityHint(isFormValid ? "Double tap to save vehicle" : "Form incomplete")
                    .accessibilityIdentifier("add_vehicle_save_button")
                    .alert("Confirm Save", isPresented: $showSaveConfirmation) {
                        Button("Cancel", role: .cancel) { }
                        Button("Save") {
                            fleetVM.addVehicle(formData)
                            presentationMode.wrappedValue.dismiss()
                        }
                    } message: {
                        Text("Are you sure you want to save this vehicle to your fleet?")
                    }
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
                                ModernTextField(icon: "number.square.fill", placeholder: "Registration No. (e.g., XX-00-XX-0000)", text: $formData.registrationNumber, isRequired: true, autocapitalization: .allCharacters)
                                    .focused($focusedField, equals: .registration)
                                    .accessibilityHint("Format: State Code, District Code, Alphabetical Series, and Number. Example: MH-14-AB-1234")
                                    .onChange(of: formData.registrationNumber) { newValue in
                                        let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                                        var clean = ""
                                        
                                        // Strictly restrict the structure as they type
                                        for (index, char) in filtered.enumerated() {
                                            if index < 2 { // First two must be letters
                                                if char.isLetter { clean.append(char) }
                                            } else if index < 4 { // Next two must be numbers
                                                if char.isNumber { clean.append(char) }
                                            } else if index < 6 { // Next two must be letters
                                                if char.isLetter { clean.append(char) }
                                            } else if index < 10 { // Next four must be numbers
                                                if char.isNumber { clean.append(char) }
                                            }
                                        }
                                        
                                        var formatted = ""
                                        for (index, char) in clean.enumerated() {
                                            if index == 2 || index == 4 || index == 6 {
                                                formatted.append("-")
                                            }
                                            formatted.append(char)
                                        }
                                        
                                        formData.registrationNumber = formatted
                                    }
                                
                                if showRegistrationError && !isValidRegistration {
                                    Text("Invalid format. Expected: XX-00-XX-0000")
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
                                    .focused($focusedField, equals: .manufacturer)
                                    .onTapGesture { validateRegistrationOnInteraction() }
                                    .onChange(of: formData.manufacturer) { newValue in
                                        if let first = newValue.first, !first.isLetter {
                                            formData.manufacturer = String(newValue.dropFirst())
                                        }
                                    }
                            }
                            
                            HStack(spacing: 16) {
                                ModernTextField(icon: "info.circle.fill", placeholder: "Model", text: $formData.model, isRequired: true)
                                    .frame(maxWidth: .infinity)
                                    .focused($focusedField, equals: .model)
                                    .onTapGesture { validateRegistrationOnInteraction() }
                                    .onChange(of: formData.model) { newValue in
                                        if let first = newValue.first, !first.isLetter {
                                            formData.model = String(newValue.dropFirst())
                                        }
                                    }
                                ModernPicker(icon: "fuelpump.fill", title: "Fuel", selection: $formData.fuelType, options: fuelTypes)
                                    .frame(maxWidth: .infinity)
                                    .simultaneousGesture(TapGesture().onEnded { validateRegistrationOnInteraction() })
                                    .onChange(of: formData.fuelType) { _ in validateRegistrationOnInteraction() }
                            }
                            
                            ModernDatePicker(icon: "calendar", title: "Registration Date", selection: $formData.registrationDate, throughDate: Date())
                                .simultaneousGesture(TapGesture().onEnded { validateRegistrationOnInteraction() })
                                .onChange(of: formData.registrationDate) { _ in validateRegistrationOnInteraction() }
                            
                            ModernTextField(icon: "scalemass.fill", placeholder: "Capacity", text: $formData.capacity, isRequired: true)
                                .focused($focusedField, equals: .capacity)
                                .onTapGesture { validateRegistrationOnInteraction() }
                                .onChange(of: formData.capacity) { newValue in
                                    formData.capacity = newValue.filter { $0.isNumber }
                                }
                                
                            ModernTextField(icon: "fuelpump.fill", placeholder: "Fuel Capacity (Liters)", text: $formData.tankCapacity, isRequired: true)
                                .onTapGesture { validateRegistrationOnInteraction() }
                                .onChange(of: formData.tankCapacity) { newValue in
                                    formData.tankCapacity = newValue.filter { $0.isNumber }
                                }
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
            // If focus moves to ANY field other than registration, check validation
            if newValue != .registration && newValue != nil {
                validateRegistrationOnInteraction()
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
    
    private var isFormValid: Bool {
        return isValidRegistration && 
               !formData.manufacturer.trimmingCharacters(in: .whitespaces).isEmpty &&
               !formData.model.trimmingCharacters(in: .whitespaces).isEmpty &&
               !formData.capacity.trimmingCharacters(in: .whitespaces).isEmpty &&
               !formData.tankCapacity.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var isValidRegistration: Bool {
        let regEx = "^[A-Z]{2}-\\d{2}-[A-Z]{2}-\\d{4}$"
        let pred = NSPredicate(format:"SELF MATCHES %@", regEx)
        return pred.evaluate(with: formData.registrationNumber.uppercased())
    }
}
