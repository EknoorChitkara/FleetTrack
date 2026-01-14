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
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Add Maintenance Staff")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Staff Details")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical)
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            VStack(spacing: 0) {
                                MSTextField(title: "Full Name", placeholder: "", text: $formData.fullName, isLast: false)
                                Divider().background(Color.gray.opacity(0.3))
                                MSTextField(title: "Specialization (e.g., Mechanic, Electrician)", placeholder: "", text: $formData.specialization, isLast: false)
                                Divider().background(Color.gray.opacity(0.3))
                                MSTextField(title: "Phone (e.g., +91 9876543210)", placeholder: "", text: $formData.phoneNumber, isLast: false)
                                Divider().background(Color.gray.opacity(0.3))
                                MSTextField(title: "Email", placeholder: "", text: $formData.email, isLast: false)
                                Divider().background(Color.gray.opacity(0.3))
                                MSTextField(title: "Employee ID", placeholder: "", text: $formData.employeeId, isLast: false)
                                Divider().background(Color.gray.opacity(0.3))
                                MSTextField(title: "Years of Experience", placeholder: "", text: $formData.yearsOfExperience, isLast: true)
                            }
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
                                    if !NSPredicate(format:"SELF MATCHES %@", "^\\+\\d{2} \\d{10}$").evaluate(with: formData.phoneNumber) {
                                        Text("• Phone must be in format +91 9876543210")
                                    }
                                    if !NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: formData.email) {
                                        Text("• Invalid email format")
                                    }
                                    if formData.specialization.isEmpty {
                                        Text("• Specialization is required")
                                    }
                                    if formData.employeeId.isEmpty {
                                        Text("• Employee ID is required")
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
                    },
                    
                    trailing: Button(action: {
                        fleetVM.addMaintenanceStaff(formData)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Save")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(!isFormValid ? .gray : .appEmerald)
                    }
                    .disabled(!isFormValid)
                )
            }
        }
    }
    
    private var isFormValid: Bool {
        guard !formData.fullName.isEmpty else { return false }
        guard !formData.specialization.isEmpty else { return false }
        guard !formData.employeeId.isEmpty else { return false }
        
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

// Helper text field component for Maintenance Staff form
private struct MSTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let isLast: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
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

// Data model for maintenance staff creation
struct MaintenanceStaffCreationData {
    var fullName: String = ""
    var specialization: String = ""
    var phoneNumber: String = ""
    var email: String = ""
    var employeeId: String = ""
    var yearsOfExperience: String = ""
}
