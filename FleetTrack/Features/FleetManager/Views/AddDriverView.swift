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
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16),
                
                trailing: Button("Save") {
                    fleetVM.addDriver(formData)
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(formData.fullName.isEmpty ? .gray : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                .background(formData.fullName.isEmpty ? Color(white: 0.1) : Color.appEmerald)
                .cornerRadius(16)
                .disabled(formData.fullName.isEmpty)
            )
        }
        }
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
