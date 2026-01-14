//
//  ServiceBookingView.swift
//  FleetTrack
//
//  Created for Driver
//

import SwiftUI

struct ServiceBookingView: View {
    @EnvironmentObject var viewModel: VehicleInspectionViewModel
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Request Service")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // Service Type Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Service Type")
                            .font(.subheadline)
                            .foregroundColor(.appSecondaryText)
                        
                        Menu {
                            ForEach(MaintenanceType.allCases, id: \.self) { type in
                                Button {
                                    viewModel.selectedServiceType = type
                                } label: {
                                    Text(type.rawValue)
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.selectedServiceType.rawValue)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.appSecondaryText)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preferred Date")
                            .font(.subheadline)
                            .foregroundColor(.appSecondaryText)
                        
                        DatePicker("", selection: $viewModel.serviceDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundColor(.appSecondaryText)
                        
                        TextEditor(text: $viewModel.serviceNotes)
                            .frame(height: 120)
                            .padding(8) // Inner padding
                            .scrollContentBackground(.hidden)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                Group {
                                    if viewModel.serviceNotes.isEmpty {
                                        Text("Describe the issue or service needed...")
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 16)
                                            .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }
                }
                .padding()
            }
            
            // Submit Button
            Button(action: {
                Task {
                    await viewModel.requestService()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text("Request Service")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appEmerald)
            .cornerRadius(12)
            .disabled(viewModel.isLoading)
            .padding()
            .background(Color.appBackground) // sticky footer bg
        }
    }
}
