//
//  FleetManagerManageMechanicsView.swift
//  FleetTrack
//
//  Created for Fleet Manager - Manage Mechanics
//

import SwiftUI

struct FleetManagerManageMechanicsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fleetVM: FleetViewModel
    @State private var mechanicToDelete: MaintenancePersonnel? = nil
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
                            .background(Color(white: 0.2))
                            .clipShape(Circle())
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Manage Mechanics")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                .padding(.top)
                
                if fleetVM.maintenancePersonnel.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "wrench.and.screwdriver.slash")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        Text("No mechanics added yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(fleetVM.maintenancePersonnel) { mechanic in
                                MechanicCard(
                                    mechanic: mechanic,
                                    onDelete: {
                                        mechanicToDelete = mechanic
                                        showDeleteAlert = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Mechanic"),
                message: Text("Are you sure you want to remove \(mechanicToDelete?.displayName ?? "this mechanic") from the fleet?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let mechanic = mechanicToDelete {
                        fleetVM.deleteMechanic(byId: mechanic.id)
                    }
                    mechanicToDelete = nil
                },
                secondaryButton: .cancel {
                    mechanicToDelete = nil
                }
            )
        }
    }
}

// MARK: - Mechanic Card Component

struct MechanicCard: View {
    let mechanic: MaintenancePersonnel
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 20))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(mechanic.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                if let email = mechanic.email {
                    Text(email)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                if let specs = mechanic.specializations, !specs.isEmpty {
                    Text(specs)
                        .font(.system(size: 12))
                        .foregroundColor(.appEmerald)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
