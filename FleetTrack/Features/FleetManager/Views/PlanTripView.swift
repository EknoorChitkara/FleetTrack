//
//  PlanTripView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct PlanTripView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fleetVM: FleetViewModel
    @State private var formData = TripCreationData()
    
    @State private var selectedVehicleString = "Choose a vehicle"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Cancel")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(white: 0.15))
                                    .cornerRadius(20)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.top)
                        
                        Text("Plan a New Trip")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 20) {
                            // Vehicle Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Select Vehicle")
                                    .foregroundColor(.appSecondaryText)
                                
                                Menu {
                                    ForEach(fleetVM.vehicles) { vehicle in
                                        Button(action: {
                                            formData.vehicleId = vehicle.id
                                            selectedVehicleString = "\(vehicle.model) (\(vehicle.registrationNumber))"
                                        }) {
                                            Text("\(vehicle.model) (\(vehicle.registrationNumber))")
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedVehicleString)
                                            .foregroundColor(selectedVehicleString == "Choose a vehicle" ? .gray : .white)
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
                            
                            // Route Details
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Route Details")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TripTextField(title: "Start Location", text: $formData.startLocation)
                                TripTextField(title: "Destination", text: $formData.destination)
                                TripTextField(title: "Distance (e.g. 350 km)", text: $formData.distance)
                            }
                            
                            // Date & Time
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Start Date & Time")
                                    .foregroundColor(.appSecondaryText)
                                
                                HStack(spacing: 16) {
                                    HStack {
                                        Text(formData.startDate, style: .date)
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
                                        ZStack {
                                            DatePicker("", selection: $formData.startDate, displayedComponents: .date)
                                                .datePickerStyle(.compact)
                                                .labelsHidden()
                                                .opacity(0.011)
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .contentShape(Rectangle())
                                    )
                                    
                                    HStack {
                                        Text(formData.startTime, style: .time)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "clock")
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
                                        ZStack {
                                            DatePicker("", selection: $formData.startTime, displayedComponents: .hourAndMinute)
                                                .datePickerStyle(.compact)
                                                .labelsHidden()
                                                .opacity(0.011)
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .contentShape(Rectangle())
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(16)
                        
                        Spacer(minLength: 20)
                        
                        // Create Button
                        Button(action: {
                            fleetVM.addTrip(formData)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Create Trip")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(formData.vehicleId == nil || formData.startLocation.isEmpty || formData.destination.isEmpty ? Color.gray : Color.appEmerald)
                                .cornerRadius(12)
                        }
                        .disabled(formData.vehicleId == nil || formData.startLocation.isEmpty || formData.destination.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct TripTextField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.appSecondaryText)
            TextField("", text: $text)
                .padding()
                .background(Color.appBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(white: 0.2), lineWidth: 1)
                )
                .foregroundColor(.white)
        }
    }
}
