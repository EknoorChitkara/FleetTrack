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
        NavigationView {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add New Driver")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Driver Details")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        VStack(spacing: 0) {
                            FMTextField(title: "Full Name", placeholder: "", text: $formData.fullName, isLast: false)
                            Divider().background(Color.gray.opacity(0.3))
                            FMTextField(title: "License Number (e.g., MH1420110062821)", placeholder: "", text: $formData.licenseNumber, isLast: false)
                            Divider().background(Color.gray.opacity(0.3))
                            FMTextField(title: "Phone (e.g., +91 9876543210)", placeholder: "", text: $formData.phoneNumber, isLast: false)
                            Divider().background(Color.gray.opacity(0.3))
                            FMTextField(title: "Email", placeholder: "", text: $formData.email, isLast: false)
                            Divider().background(Color.gray.opacity(0.3))
                            FMTextField(title: "Address", placeholder: "", text: $formData.address, isLast: true)
                        }
                        .background(Color(white: 0.15))
                        .cornerRadius(12)
                        
                        // Status Picker
                        HStack {
                            Text("Status")
                                .foregroundColor(.white)
                            Spacer()
                            Picker("Status", selection: $formData.status) {
                                ForEach(statuses, id: \.self) { status in
                                    Text(status.rawValue).tag(status)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .accentColor(.white)
                        }
                        .padding()
                        .background(Color(white: 0.15))
                        .cornerRadius(12)
                    }
                    
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
                .padding()
            }
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                },
                
                trailing: Button(action: {
                    fleetVM.addDriver(formData)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(!isFormValid ? .gray : .black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(!isFormValid ? Color(white: 0.2) : Color.appEmerald)
                        .clipShape(Capsule())
                }
                .disabled(!isFormValid)
            )
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(fleetVM.errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK")) {
                        fleetVM.errorMessage = nil
                    }
                )
            }
            .onChange(of: fleetVM.errorMessage) { newValue in
                if newValue != nil {
                    showError = true
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

// Renamed helper to avoid collision with AddVehicleView's CustomTextField
private struct FMTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let isLast: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title) // In the screenshot, the title acts more like a placeholder or label inside
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 12)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .padding(.bottom, 12)
            
            if !isLast {
                // Divider handled by parent
            }
        }
        .padding(.horizontal)
    }
}
