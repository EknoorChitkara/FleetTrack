//
//  PlanTripView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//  Updated to match new TripCreationData model
//

import SwiftUI

struct PlanTripView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fleetVM: FleetViewModel
    @State private var formData = TripCreationData()
    
    @State private var distanceString = ""
    
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
                    Text("New Trip")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        formData.distance = Double(distanceString)
                        fleetVM.addTrip(formData)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Create")
                            .fontWeight(.bold)
                            .foregroundColor(!isFormValid ? .gray : .appEmerald)
                    }
                    .disabled(!isFormValid)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        ModernFormHeader(
                            title: "Plan Trip",
                            subtitle: "Configure route and schedule",
                            iconName: "map.fill"
                        )
                        
                        VStack(spacing: 16) {
                            ModernVehiclePicker(icon: "car.fill", selection: $formData.vehicleId, vehicles: fleetVM.vehicles, placeholder: "Select Vehicle")
                                .onChange(of: formData.vehicleId) { newValue in
                                    if let vehicleId = newValue,
                                       let vehicle = fleetVM.vehicles.first(where: { $0.id == vehicleId }),
                                       let driverId = vehicle.assignedDriverId {
                                        formData.driverId = driverId
                                    }
                                }
                            
                            ModernDriverPicker(icon: "person.fill", selection: $formData.driverId, drivers: fleetVM.drivers, placeholder: "Select Driver")
                            
                            ModernTextField(icon: "mappin.and.ellipse", placeholder: "Start Location", text: $formData.startAddress, isRequired: true)
                            
                            ModernTextField(icon: "flag.checkered", placeholder: "Destination", text: $formData.endAddress, isRequired: true)
                            
                            HStack(spacing: 16) {
                                ModernTextField(icon: "arrow.left.and.right", placeholder: "Distance (km)", text: $distanceString, keyboardType: .decimalPad)
                                    .frame(maxWidth: .infinity)
                                
                                ModernTextField(icon: "info.circle", placeholder: "Purpose", text: $formData.purpose)
                                    .frame(maxWidth: .infinity)
                            }
                            
                            HStack(spacing: 16) {
                                ModernDatePicker(icon: "calendar", title: "Date", selection: $formData.startTime, components: .date, fromDate: Date())
                                    .frame(maxWidth: .infinity)
                                
                                ModernDatePicker(icon: "clock", title: "Time", selection: $formData.startTime, components: .hourAndMinute)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        formData.vehicleId != nil && 
        formData.driverId != nil && 
        !formData.startAddress.isEmpty && 
        !formData.endAddress.isEmpty
    }
}
