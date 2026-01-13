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
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.appEmerald)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(driver.fullName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(driver.licenseNumber)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(driver.status.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(driver.status == .available ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .foregroundColor(driver.status == .available ? .green : .gray)
                    .cornerRadius(6)
                
                Text(driver.phoneNumber)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
    }
}
