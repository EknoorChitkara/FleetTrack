//
//  FleetManagerManageDriversView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct FleetManagerManageDriversView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fleetVM: FleetViewModel
    @State private var driverToDelete: FMDriver? = nil
    @State private var showDeleteAlert = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack {
                // Custom Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .padding(10)
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Back")
                    .accessibilityIdentifier("manage_drivers_back_button")
                    
                    Spacer()
                    
                    Text("Manage Drivers")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                .padding(.top)
                
                if fleetVM.drivers.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        Text("No drivers added yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(fleetVM.drivers) { driver in
                                DriverCard(
                                    driver: driver,
                                    onDelete: {
                                        driverToDelete = driver
                                        showDeleteAlert = true
                                    }
                                )
                            }
                        }
                        .padding()
                        .accessibilityIdentifier("manage_drivers_list")
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Driver"),
                message: Text("Are you sure you want to remove \(driverToDelete?.displayName ?? "this driver") from the fleet?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let driver = driverToDelete {
                        fleetVM.deleteDriver(byId: driver.id)
                    }
                    driverToDelete = nil
                },
                secondaryButton: .cancel {
                    driverToDelete = nil
                }
            )
        }
    }
}

