//
//  InspectionChecklistView.swift
//  FleetTrack
//
//  Created for Driver
//

import SwiftUI

struct InspectionChecklistView: View {
    @EnvironmentObject var viewModel: VehicleInspectionViewModel
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Daily Checklist")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ForEach(viewModel.checklists) { item in
                            InspectionChecklistRow(item: item) {
                                viewModel.toggleItemStatus(id: item.id)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Add Photo Section
                    Button(action: {
                        // Photo upload action
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Add photo (optional)")
                        }
                        .foregroundColor(.appSecondaryText)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
            
            // Submit Button
            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        await viewModel.submitInspection()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text("Submit Inspection")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.appEmerald)
                .cornerRadius(12)
                .disabled(viewModel.isLoading)
                
                Button(action: {
                    // Report Issue action
                }) {
                    Text("Report Issue")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
            .background(Color.appCardBackground)
        }
    }
}

struct InspectionChecklistRow: View {
    let item: InspectionItem
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(item.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(item.status == .pass ? Color.appEmerald : Color.white.opacity(0.1))
                        .frame(width: 24, height: 24)
                    
                    if item.status == .pass {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}
