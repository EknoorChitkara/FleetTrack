//
//  FleetManagerDashboardView.swift
//  FleetTrack
//
//  Created by FleetTrack on 08/01/26.
//

import SwiftUI

struct FleetManagerDashboardView: View {
    let user: User
    @StateObject private var fleetVM = FleetViewModel.shared
    
    // Tab State
    @State private var selectedTab: Tab = .dashboard
    
    // Sheet State
    @State private var showCreateTrip = false
    @State private var showAddVehicle = false
    @State private var showAddDriver = false
    @State private var showProfile = false
    
    // Enums for Tabs
    enum Tab {
        case dashboard
        case vehicles
        case alerts
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                // Main Content
                Group {
                    switch selectedTab {
                    case .dashboard:
                        FleetManagerHomeView(
                            user: user,
                            showCreateTrip: $showCreateTrip,
                            showAddVehicle: $showAddVehicle,
                            showAddDriver: $showAddDriver,
                            showProfile: $showProfile
                            
                        )
                        .environmentObject(fleetVM)
                    case .vehicles:
                        FleetManagerVehiclesView()
                            .environmentObject(fleetVM)
                    case .alerts:
                        FleetManagerAlertsView()
                    }
                }
                
                // Custom Bottom Tab Bar (Overlay)
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: $selectedTab)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreateTrip) {
                PlanTripView().environmentObject(fleetVM)
            }
            .sheet(isPresented: $showAddVehicle) {
                AddVehicleView().environmentObject(fleetVM)
            }
            .sheet(isPresented: $showAddDriver) {
                AddDriverView().environmentObject(fleetVM)
            }
            .sheet(isPresented: $showProfile) {
                FleetManagerProfileView(user: user).environmentObject(fleetVM)
            }
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: FleetManagerDashboardView.Tab
    
    var body: some View {
        HStack(spacing: 0) {
            FleetManagerTabBarItem(icon: "house.fill", title: "Dashboard", isSelected: selectedTab == .dashboard) {
                selectedTab = .dashboard
            }
            FleetManagerTabBarItem(icon: "car.fill", title: "Vehicles", isSelected: selectedTab == .vehicles) {
                selectedTab = .vehicles
            }
            FleetManagerTabBarItem(icon: "bell.fill", title: "Alerts", isSelected: selectedTab == .alerts) {
                selectedTab = .alerts
            }
        }
        .padding(.vertical, 14)
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .clipShape(Capsule())
        .padding(.horizontal, 40)
        .padding(.bottom, 8)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct FleetManagerTabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .appEmerald : .gray)
                
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .appEmerald : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        //    },
    }
}
