//
//  DriverInspectionViews.swift
//  FleetTrack
//
//  Created for Driver App
//

import SwiftUI

// MARK: - Main Container

struct DriverVehicleInspectionView: View {
    @StateObject var viewModel: VehicleInspectionViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Text("Vehicle Inspection")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        // Profile or other action
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                
                Text("Daily checklist & maintenance")
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom)
                
                // Custom Tab Bar
                InspectionTabBar(selectedTab: $viewModel.selectedTab)
                    .padding(.horizontal)
                    .padding(.bottom)
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch viewModel.selectedTab {
                        case .summary:
                            InspectionSummaryView(viewModel: viewModel)
                        case .checklist:
                            InspectionChecklistView(viewModel: viewModel)
                        case .history:
                            InspectionHistoryView(viewModel: viewModel)
                        case .booking:
                            InspectionBookingView(viewModel: viewModel)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $viewModel.showingConfirmation) {
            Alert(title: Text("Success"), message: Text(viewModel.confirmationMessage), dismissButton: .default(Text("OK")))
        }
    }
}

// MARK: - Components

struct InspectionTabBar: View {
    @Binding var selectedTab: InspectionTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(InspectionTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedTab == tab ? .black : .appSecondaryText)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedTab == tab ? Color.appEmerald : Color.clear
                        )
                        .cornerRadius(12)
                }
            }
        }
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Tab Views

struct InspectionSummaryView: View {
    @ObservedObject var viewModel: VehicleInspectionViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Assigned Vehicle
            VStack(alignment: .leading, spacing: 12) {
                Text("Assigned Vehicle")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let vehicle = viewModel.vehicle {
                    VStack(spacing: 20) {
                        // Vehicle Info Row
                        HStack(spacing: 16) {
                            Image(systemName: "truck.box.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(16)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(vehicle.registrationNumber)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("\(vehicle.manufacturer) \(vehicle.model)")
                                    .font(.subheadline)
                                    .foregroundColor(.appSecondaryText)
                            }
                            Spacer()
                        }
                        
                        // Status Rows
                        VStack(spacing: 12) {
                            HStack {
                                Text("Vehicle Status")
                                    .foregroundColor(.appSecondaryText)
                                Spacer()
                                Text(vehicle.status.rawValue)
                                    .foregroundColor(vehicle.status == .active ? .appEmerald : .orange)
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Text("Last Service")
                                    .foregroundColor(.appSecondaryText)
                                Spacer()
                                Text(vehicle.lastService?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                        }
                        
                        // Details Button
                        Button {
                            // View details action
                        } label: {
                            Text("View Vehicle Details")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(20)
                    .background(Color.appCardBackground)
                    .cornerRadius(16)
                    
                } else {
                    Text("No vehicle assigned")
                        .foregroundColor(.appSecondaryText)
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(16)
                }
            }
            
            // Quick Actions
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Actions")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Button {
                    withAnimation {
                        viewModel.selectedTab = .checklist
                    }
                } label: {
                    Text("Start Daily Inspection")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Button {
                    // Navigate to reporting
                } label: {
                    Text("Report Issue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(16)
        }
    }
}

struct InspectionChecklistView: View {
    @ObservedObject var viewModel: VehicleInspectionViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Daily Checklist")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(viewModel.checklistItems) { item in
                    Button {
                        viewModel.markItemAsChecked(item.id)
                    } label: {
                        HStack {
                            Text(item.name)
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundColor(item.isChecked ? .appEmerald : .gray)
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(12)
                    }
                }
                
                // Submit
                Button {
                    Task {
                        await viewModel.submitInspection()
                    }
                } label: {
                    Text("Submit Inspection")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appEmerald)
                        .cornerRadius(12)
                }
                
                Button("Report Issue") {
                    // Report action
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

struct InspectionHistoryView: View {
        @ObservedObject var viewModel: VehicleInspectionViewModel
        
        var body: some View {
            VStack(spacing: 16) {
                if viewModel.historyRecords.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(.appSecondaryText)
                        Text("No inspection history yet")
                            .font(.headline)
                            .foregroundColor(.appSecondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(viewModel.historyRecords) { record in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(record.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                    .foregroundColor(.appSecondaryText)
                            }
                            
                            Text(record.status)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(record.color) // e.g., appEmerald
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(record.color.opacity(0.2))
                                .cornerRadius(4)
                            
                            Text(record.description)
                                .font(.subheadline)
                                .foregroundColor(.appSecondaryText)
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(16)
                    }
                }
            }
        }
    }

struct InspectionBookingView: View {
    @ObservedObject var viewModel: VehicleInspectionViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Request Service")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Service Type")
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                
                Menu {
                    ForEach(ServiceType.allCases) { type in
                        Button(type.rawValue) {
                            viewModel.selectedServiceType = type
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
                    .background(Color.appCardBackground)
                    .cornerRadius(12)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Preferred Date")
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                
                // Custom Text Field with DatePicker
                // We puts the DatePicker 'behind' the custom view but scale it up to fill the space.
                // The custom view must allow hit testing to pass through to the underlying picker.
                ZStack {
                    // Layer 1: The functionality (Invisible but touchable giant picker)
                    DatePicker("", selection: $viewModel.preferredDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .scaleEffect(x: 10, y: 5) // Scale up to cover the whole container
                        .opacity(0.02) // Almost invisible but interactive
                    
                    // Layer 2: The Design (Non-interactive visual only)
                    HStack {
                        Text(viewModel.preferredDate.formatted(.dateTime.day().month().year()))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "calendar")
                            .foregroundColor(.appSecondaryText)
                    }
                    .padding()
                    .background(Color.appCardBackground)
                    .cornerRadius(12)
                    .allowsHitTesting(false) // Pass touches to the DatePicker below
                }
                .clipped() // Clip the giant picker to the rounded bounds
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                
                TextEditor(text: $viewModel.notes)
                    .frame(height: 100)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.appCardBackground)
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .overlay(
                        Group {
                            if viewModel.notes.isEmpty {
                                Text("Describe the issue or service needed...")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 12)
                                    .padding(.top, 16)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            }
            
            Button(action: viewModel.submitServiceRequest) {
                Text("Request Service")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appEmerald)
                    .cornerRadius(12)
            }
        }
    }
}
