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
    @State private var showSuccessAlert = false
    
    // Mock Data
    let statuses = DriverStatus.allCases
    
    // Phone State
    @State private var selectedCountryCode = "+91"
    @State private var localPhoneNumber = ""
    
    private func updatePhoneNumber() {
        formData.phoneNumber = "\(selectedCountryCode) \(localPhoneNumber)"
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
                        showSuccessAlert = true
                    }) {
                        Text("Save")
                            .fontWeight(.bold)
                            .foregroundColor(!isFormValid ? .gray : .appEmerald)
                    }
                    .disabled(!isFormValid)
                    .alert(isPresented: $showSuccessAlert) {
                        Alert(
                            title: Text("Success"),
                            message: Text("Driver added successfully"),
                            dismissButton: .default(Text("OK")) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        )
                    }
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
                            ModernTextField(icon: "person.fill", placeholder: "Full Name", text: $formData.fullName, isRequired: true)
                                .onChange(of: formData.fullName) { newValue in
                                    if newValue.count > 50 {
                                        formData.fullName = String(newValue.prefix(50))
                                    }
                                }
                            
                            // License Number with Validation
                            VStack(alignment: .leading, spacing: 4) {
                                ModernTextField(icon: "creditcard.fill", placeholder: "License Number XX0000000000000", text: $formData.licenseNumber, isRequired: true)
                                    .onChange(of: formData.licenseNumber) { newValue in
                                        let limited = String(newValue.prefix(15)).uppercased()
                                        if limited != newValue {
                                            formData.licenseNumber = limited
                                        }
                                    }
                                
                                if !formData.licenseNumber.isEmpty && !NSPredicate(format:"SELF MATCHES %@", "^[A-Z]{2}\\d{13}$").evaluate(with: formData.licenseNumber) {
                                    Text("License must be 2 letters + 13 digits")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading)
                                }
                            }
                            
                            // Phone Number with Validation
                            VStack(alignment: .leading, spacing: 4) {
                                // Composite Phone Number Field
                                HStack(spacing: 12) {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.gray)
                                        .frame(width: 24)
                                    
                                    // Country Code Picker
                                    Menu {
                                        ForEach(["+91", "+1", "+44", "+61", "+81", "+971"], id: \.self) { code in
                                            Button(code) {
                                                selectedCountryCode = code
                                                updatePhoneNumber()
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(selectedCountryCode)
                                                .foregroundColor(.white)
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    
                                    // Phone Number Input
                                    ZStack(alignment: .leading) {
                                        if localPhoneNumber.isEmpty {
                                            Text("xxxxxxxxxx")
                                                .foregroundColor(.gray.opacity(0.6))
                                        }
                                        TextField("", text: $localPhoneNumber)
                                            .keyboardType(.numberPad)
                                            .foregroundColor(.white)
                                            .onChange(of: localPhoneNumber) { newValue in
                                                let filtered = newValue.filter { $0.isNumber }
                                                if filtered.count > 10 {
                                                    localPhoneNumber = String(filtered.prefix(10))
                                                } else {
                                                    localPhoneNumber = filtered
                                                }
                                                updatePhoneNumber()
                                            }
                                    }
                                    
                                    if formData.phoneNumber.isEmpty { // Show required asterisk if empty
                                         Text("*")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.horizontal)
                                .frame(height: 60)
                                .background(Color.appCardBackground)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                )
                                
                                if !formData.phoneNumber.isEmpty && !NSPredicate(format:"SELF MATCHES %@", "^\\+\\d{2} \\d{10}$").evaluate(with: formData.phoneNumber) {
                                    Text("Phone must be in format +91 9876543210")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading)
                                }
                            }
                            
                            // Email with Validation
                            VStack(alignment: .leading, spacing: 4) {
                                ModernTextField(icon: "envelope.fill", placeholder: "Email", text: $formData.email, isRequired: true, keyboardType: .emailAddress)
                                
                                // Matches standard email regex used in bottom validation
                                if !formData.email.isEmpty && !NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: formData.email) {
                                    Text("Invalid email format")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading)
                                }
                            }
                            
                            ModernTextField(icon: "house.fill", placeholder: "Address", text: $formData.address, isRequired: true)
                        }
                        .padding(.horizontal)
                        
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
