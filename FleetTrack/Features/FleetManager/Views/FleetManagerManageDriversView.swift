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
                            .background(Color(white: 0.2))
                            .clipShape(Circle())
                            .foregroundColor(.white)
                    }
                    
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
                                DriverCard(driver: driver)
                                    .environmentObject(fleetVM)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct DriverCard: View {
    let driver: FMDriver
    @EnvironmentObject var fleetVM: FleetViewModel
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.appEmerald)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(driver.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(driver.licenseNumber ?? "No License")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                let status = driver.status ?? .available
                Text(status.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status == .available ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .foregroundColor(status == .available ? .green : .gray)
                    .cornerRadius(6)
                
                Text(driver.phoneNumber ?? "No Phone")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            
            // Delete Button
            Button(action: {
                showDeleteAlert = true
            }) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .alert("Delete Driver", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteDriver()
            }
        } message: {
            Text("Are you sure you want to delete \(driver.displayName)? This action cannot be undone.")
        }
    }
    
    private func deleteDriver() {
        // Remove driver from the fleet view model
        fleetVM.drivers.removeAll { $0.id == driver.id }
        print("Driver deleted: \(driver.displayName)")
    }
}
