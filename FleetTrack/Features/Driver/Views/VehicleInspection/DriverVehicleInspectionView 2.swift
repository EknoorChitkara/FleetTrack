//
//  VehicleInspectionView.swift
//  FleetTrack
//
//  Created for Driver
//

import SwiftUI

enum InspectionTab: String, CaseIterable {
    case summary = "Summary"
    case checklist = "Checklist"
    case history = "History"
    case booking = "Booking"
}

struct DriverVehicleInspectionView: View {
    @StateObject private var viewModel: VehicleInspectionViewModel
    @State private var selectedTab: InspectionTab
    @Environment(\.presentationMode) var presentationMode
    
    // Initializer to accept user and optional initial tab
    init(user: User, initialTab: InspectionTab = .summary) {
        _viewModel = StateObject(wrappedValue: VehicleInspectionViewModel(userId: user.id))
        _selectedTab = State(initialValue: initialTab)
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vehicle Inspection")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Daily checklist & maintenance")
                            .font(.caption)
                            .foregroundColor(.appSecondaryText)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    // Profile/User icon placeholder if needed
                }
                .padding()
                
                // Custom Segmented Control
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(InspectionTab.allCases, id: \.self) { tab in
                            Button(action: {
                                withAnimation {
                                    selectedTab = tab
                                }
                            }) {
                                Text(tab.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(selectedTab == tab ? Color.appEmerald : Color.white.opacity(0.05))
                                    .foregroundColor(selectedTab == tab ? .black : .appSecondaryText)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                
                // Content
                if viewModel.isLoading && viewModel.assignedVehicle == nil {
                    Spacer()
                    ProgressView()
                        .tint(.appEmerald)
                    Spacer()
                } else if let vehicle = viewModel.assignedVehicle {
                    TabView(selection: $selectedTab) {
                        InspectionSummaryView(vehicle: vehicle)
                            .tag(InspectionTab.summary)
                            .environmentObject(viewModel)
                        
                        InspectionChecklistView()
                            .tag(InspectionTab.checklist)
                            .environmentObject(viewModel)
                        
                        InspectionHistoryView()
                            .tag(InspectionTab.history)
                            .environmentObject(viewModel)
                        
                        ServiceBookingView()
                            .tag(InspectionTab.booking)
                            .environmentObject(viewModel)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                } else {
                    Spacer()
                    Text("No vehicle assigned")
                        .foregroundColor(.appSecondaryText)
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadData()
        }
    }
}
