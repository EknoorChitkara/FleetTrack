//
//  AddMaintenanceStaffView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct AddMaintenanceStaffView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fleetVM: FleetViewModel
    @State private var formData = MaintenanceStaffCreationData()
    
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
                    Text("Add Staff")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        fleetVM.addMaintenanceStaff(formData)
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
                            title: "Staff Details",
                            subtitle: "Register new maintenance personnel",
                            iconName: "wrench.and.screwdriver.fill"
                        )
                        
                        VStack(spacing: 16) {
                            ModernTextField(icon: "person.fill", placeholder: "Full Name", text: $formData.fullName, isRequired: true)
                            
                            ModernTextField(icon: "star.fill", placeholder: "Specialization (e.g., Mechanic)", text: $formData.specialization, isRequired: true)
                            
                            ModernTextField(icon: "phone.fill", placeholder: "Phone (e.g., +91 9876543210)", text: $formData.phoneNumber, isRequired: true, keyboardType: .phonePad)
                            
                            ModernTextField(icon: "envelope.fill", placeholder: "Email", text: $formData.email, isRequired: true, keyboardType: .emailAddress)
                            
                            ModernTextField(icon: "briefcase.fill", placeholder: "Experience (Yrs)", text: $formData.yearsOfExperience, keyboardType: .numberPad)
                        }
                        .padding(.horizontal)
                        
                        if !formData.fullName.isEmpty && !isFormValid {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Please correct the following:")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                
                                Group {
                                    if !NSPredicate(format:"SELF MATCHES %@", "^\\+\\d{2} \\d{10}$").evaluate(with: formData.phoneNumber) {
                                        Text("• Phone must be in format +91 9876543210")
                                    }
                                    if !NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: formData.email) {
                                        Text("• Invalid email format")
                                    }
                                    if formData.specialization.isEmpty {
                                        Text("• Specialization is required")
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
        guard !formData.specialization.isEmpty else { return false }
        
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

// Data model for maintenance staff creation
struct MaintenanceStaffCreationData {
    var fullName: String = ""
    var specialization: String = ""
    var phoneNumber: String = ""
    var email: String = ""
    var employeeId: String = ""
    var yearsOfExperience: String = ""
}
