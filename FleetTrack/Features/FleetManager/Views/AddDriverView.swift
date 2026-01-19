//
//  AddDriverView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct AddDriverView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fleetVM: FleetViewModel
    @State private var formData = DriverCreationData()
    @State private var showError = false
    
    // Mock Data
    let statuses = DriverStatus.allCases
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("Add Driver")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        fleetVM.addDriver(formData)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Save")
                            .fontWeight(.bold)
                            .foregroundColor(!isFormValid ? .gray : .appEmerald)
                    }
                    .disabled(!isFormValid)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        ModernFormHeader(
                            title: "Driver Details",
                            subtitle: "Enter personal and license information",
                            iconName: "person.badge.plus.fill"
                        )
                        
                        VStack(spacing: 16) {
                            ModernTextField(icon: "person.fill", placeholder: "Full Name", text: Binding(
                                get: { formData.fullName },
                                set: { formData.fullName = String($0.prefix(50)) }
                            ), isRequired: true)
                            
                            ModernTextField(icon: "creditcard.fill", placeholder: "License Number (e.g., MH1420110062821)", text: $formData.licenseNumber, isRequired: true)
                            
                            ModernTextField(icon: "phone.fill", placeholder: "Phone (e.g., +91 9876543210)", text: $formData.phoneNumber, isRequired: true, keyboardType: .phonePad)
                            
                            ModernTextField(icon: "envelope.fill", placeholder: "Email", text: $formData.email, isRequired: true, keyboardType: .emailAddress)
                            
                            ModernTextField(icon: "house.fill", placeholder: "Address", text: $formData.address, isRequired: true)
                        }
                        .padding(.horizontal)
                        
                        if !formData.fullName.isEmpty && !isFormValid {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Please correct the following:")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                
                                Group {
                                    if !NSPredicate(format:"SELF MATCHES %@", "^[A-Z]{2}\\d{13}$").evaluate(with: formData.licenseNumber) {
                                        Text("• License must be 2 letters + 13 digits")
                                    }
                                    if !NSPredicate(format:"SELF MATCHES %@", "^\\+\\d{2} \\d{10}$").evaluate(with: formData.phoneNumber) {
                                        Text("• Phone must be in format +91 9876543210")
                                    }
                                    if !NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: formData.email) {
                                        Text("• Invalid email format")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.8))
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        guard !formData.fullName.isEmpty else { return false }
        
        // License: MH1420110062821 (2 letters + 13 digits)
        let licenseRegEx = "^[A-Z]{2}\\d{13}$"
        let licensePred = NSPredicate(format:"SELF MATCHES %@", licenseRegEx)
        guard licensePred.evaluate(with: formData.licenseNumber) else { return false }
        
        // Phone: +91 9876543210
        let phoneRegEx = "^\\+\\d{2} \\d{10}$"
        let phonePred = NSPredicate(format:"SELF MATCHES %@", phoneRegEx)
        guard phonePred.evaluate(with: formData.phoneNumber) else { return false }
        
        // Email
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        guard emailPred.evaluate(with: formData.email) else { return false }
        
        return true
    }
}
