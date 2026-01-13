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
    
    // Form data
    @State private var fullName: String = ""
    @State private var employeeId: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var specialization: String = ""
    @State private var experience: String = ""
    @State private var address: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        HStack {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                                .padding(12)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Add Maintenance Staff")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Fill in the details below")
                                    .font(.subheadline)
                                    .foregroundColor(.appSecondaryText)
                            }
                        }
                        .padding(.top)
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            Group {
                                CustomTextField(title: "Full Name", placeholder: "Enter full name", text: $fullName, isRequired: true)
                                    .padding(.bottom, 16)
                                
                                CustomTextField(title: "Employee ID", placeholder: "e.g., EMP001", text: $employeeId, isRequired: true)
                                
                                CustomTextField(title: "Phone Number", placeholder: "e.g., +91 98765 43210", text: $phoneNumber, isRequired: true)
                                
                                CustomTextField(title: "Email", placeholder: "e.g., staff@example.com", text: $email, isRequired: true)
                                
                                CustomTextField(title: "Specialization", placeholder: "e.g., Engine Specialist", text: $specialization, isRequired: false)
                            }
                            
                            Group {
                                CustomTextField(title: "Experience (Years)", placeholder: "e.g., 5", text: $experience, isRequired: false)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Address")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    TextEditor(text: $address)
                                        .frame(height: 80)
                                        .padding(8)
                                        .background(Color(white: 0.15))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(white: 0.2), lineWidth: 1)
                                        )
                                        .foregroundColor(.white)
                                }
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
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                addMaintenanceStaff()
                            }) {
                                Text("Add Staff")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(!isFormValid ? Color.gray : Color.orange)
                                    .cornerRadius(12)
                            }
                            .disabled(!isFormValid)
                        }
                        
                        if !isFormValid && !fullName.isEmpty {
                            Text("Please fill in all required fields")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                        
                        Text("* Indicates required field")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty && 
        !employeeId.isEmpty && 
        !phoneNumber.isEmpty && 
        !email.isEmpty &&
        email.contains("@")
    }
    
    private func addMaintenanceStaff() {
        // TODO: Implement actual database insertion
        print("Adding maintenance staff:")
        print("Name: \(fullName)")
        print("Employee ID: \(employeeId)")
        print("Phone: \(phoneNumber)")
        print("Email: \(email)")
        print("Specialization: \(specialization)")
        print("Experience: \(experience)")
        print("Address: \(address)")
        
        // Dismiss the view
        presentationMode.wrappedValue.dismiss()
    }
}
