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
    @State private var showAddMaintenanceStaff = false
    
    // Enums for Tabs
    enum Tab {
        case dashboard
        case vehicles
        case trips
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
                            showProfile: $showProfile,
                            showAddMaintenanceStaff: $showAddMaintenanceStaff
                        )
                        .environmentObject(fleetVM)
                    case .vehicles:
                        FleetManagerVehiclesView()
                            .environmentObject(fleetVM)
                    case .trips:
                        AllTripsView()
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
            .sheet(isPresented: $showAddMaintenanceStaff) {
                AddMaintenanceStaffView().environmentObject(fleetVM)
            }
        }
        .onAppear {
            InAppVoiceManager.shared.speak(voiceSummary())
        }
        .onChange(of: selectedTab) { _ in
            InAppVoiceManager.shared.speak(voiceSummary())
        }
        .onChange(of: fleetVM.isLoading) { isLoading in
            if !isLoading {
                Task {
                    // Speak summary once data is loaded
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    InAppVoiceManager.shared.speak(voiceSummary())
                }
            }
        }
    }
}

// MARK: - InAppVoiceReadable
extension FleetManagerDashboardView: InAppVoiceReadable {
    func voiceSummary() -> String {
        switch selectedTab {
        case .dashboard:
            var summary = "Fleet Manager Dashboard. "
            
            // Stats
            // Note: Since we don't have direct access to the stats view model properties here (they are in FleetHomeView),
            // we should ideally expose them or access them via fleetVM if available.
            // Assuming fleetVM has some of these or we just give a general overview if data isn't directly reachable in this wrapper.
            // However, looking at the code, FleetManagerHomeView has the stats. 
            // Let's check if FleetViewModel has summary data.
            // If not, we'll provide a high-level overview of what's on screen.
            
            summary += "Overview. "
            // Compute stats directly from fleetVM arrays
            if !fleetVM.isLoading {
                let totalVehicles = fleetVM.vehicles.count
                let activeDrivers = fleetVM.drivers.filter { $0.status == .onTrip || $0.status == .available }.count
                let inMaintenance = fleetVM.vehicles.filter { $0.status == .inMaintenance }.count
                let ongoingTrips = fleetVM.trips.count // Matches HomeView visual logic
                
                summary += "\(totalVehicles) Total Vehicles. "
                summary += "\(activeDrivers) Active Drivers. "
                summary += "\(inMaintenance) In Maintenance. "
                summary += "\(ongoingTrips) Ongoing Trips. "
            } else {
                 summary += "Loading statistics. "
            }
            
            summary += "Quick Actions: Create Trip, Add Vehicle, Add Driver, Add Maintenance. "
            summary += "Quick Links: View Geofencing, View Analytics. "
            
            return summary
        case .vehicles:
            return "" // Handled by FleetManagerVehiclesView
        case .trips:
            return "" // Handled by AllTripsView
        case .alerts:
            return "Fleet Alerts. Review system notifications and issues."
        }
    }
}


struct CustomTabBar: View {
    @Binding var selectedTab: FleetManagerDashboardView.Tab
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(icon: "house.fill", title: "Home", isSelected: selectedTab == .dashboard) {
                selectedTab = .dashboard
            }
            TabBarItem(icon: "car.fill", title: "Vehicles", isSelected: selectedTab == .vehicles) {
                selectedTab = .vehicles
            }
            TabBarItem(icon: "map.fill", title: "Trips", isSelected: selectedTab == .trips) {
                selectedTab = .trips
            }
            TabBarItem(icon: "bell.fill", title: "Alerts", isSelected: selectedTab == .alerts) {
                selectedTab = .alerts
            }
        }
        .padding(.vertical, 12)
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .clipShape(Capsule())
        .padding(.horizontal, 30)
        .padding(.bottom, 8)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct TabBarItem: View {
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
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title) tab")
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
            .accessibilityIdentifier("fleet_tab_\(title.lowercased())")
        }
        //    },
    }
}
