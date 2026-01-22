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
    @State private var isShowingReportIssue = false
    
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
                            InspectionSummaryView(viewModel: viewModel, isShowingReportIssue: $isShowingReportIssue)
                        case .checklist:
                            InspectionChecklistView(viewModel: viewModel, isShowingReportIssue: $isShowingReportIssue)
                        case .history:
                            InspectionHistoryView(viewModel: viewModel)
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
        .fullScreenCover(isPresented: $isShowingReportIssue) {
            ReportIssueView(vehicle: viewModel.vehicle)
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
                .accessibilityLabel("\(tab.rawValue) tab")
                .accessibilityAddTraits(selectedTab == tab ? [.isSelected] : [])
                .accessibilityIdentifier("inspection_tab_\(tab.rawValue.lowercased())")
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
    @Binding var isShowingReportIssue: Bool
    
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
            
            // Future Scope: Tyre Cost Calculation
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Future Scope: Tyre Cost")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "info.circle")
                        .foregroundColor(.appEmerald)
                }
                
                Text("Upcoming AI-powered tyre wear analysis and cost estimation based on driving patterns.")
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                    Text("Eco-Drive Analysis Incoming")
                        .font(.caption)
                        .foregroundColor(.appEmerald)
                }
            }
            .padding(20)
            .background(Color.appCardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appEmerald.opacity(0.3), lineWidth: 1)
            )
            
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
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appEmerald)
                        .cornerRadius(12)
                }
                .accessibilityIdentifier("inspection_start_button")
                
                Button {
                    isShowingReportIssue = true
                } label: {
                    Text("Report Issue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
                .accessibilityIdentifier("inspection_report_issue_button")
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(16)
        }
    }
}

struct InspectionChecklistView: View {
    @ObservedObject var viewModel: VehicleInspectionViewModel
    @Binding var isShowingReportIssue: Bool
    
    private var allItemsChecked: Bool {
        viewModel.checklistItems.allSatisfy { $0.isChecked }
    }
    
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
                            Image(systemName: (viewModel.isSubmitted || item.isChecked) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundColor((viewModel.isSubmitted || item.isChecked) ? .appEmerald : .gray)
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isSubmitted)
                }
                
                // Submit button - only shown when all items are checked and not yet submitted
                if allItemsChecked && !viewModel.isSubmitted {
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
                } else if viewModel.isSubmitted {
                    // Show submitted state
                    Button {} label: {
                        Text("Submitted")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(true)
                } else {
                    // Show disabled submit button when not all items are checked
                    Button {} label: {
                        Text("Submit Inspection")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.5))
                            .cornerRadius(12)
                    }
                    .disabled(true)
                }
                
                // Report Issue button - disabled when all items checked or submitted
                Button("Report Issue") {
                    isShowingReportIssue = true
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity((allItemsChecked || viewModel.isSubmitted) ? 0.3 : 1.0))
                .cornerRadius(12)
                .disabled(allItemsChecked || viewModel.isSubmitted)
                .accessibilityIdentifier("inspection_checklist_report_button")
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
            .onAppear {
                Task {
                    await viewModel.fetchHistory()
                }
            }
        }
    }
