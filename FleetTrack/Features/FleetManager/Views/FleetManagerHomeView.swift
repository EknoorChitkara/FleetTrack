//
//  FleetManagerHomeView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct FleetManagerHomeView: View {
    let user: User
    @EnvironmentObject var fleetVM: FleetViewModel
    @Binding var showCreateTrip: Bool
    @Binding var showAddVehicle: Bool
    @Binding var showAddDriver: Bool
    @Binding var showProfile: Bool
    @Binding var showAddMaintenanceStaff: Bool
    @State private var showGeofencing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Area
                headerView
                    .padding(.top, 20) // Reduced top padding
                
                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(title: "Total Vehicles", value: "\(fleetVM.vehicles.count)", icon: "car.fill", color: .appEmerald)
                    StatCard(title: "Active Drivers", value: "\(fleetVM.drivers.filter { $0.status == .available || $0.status == .onTrip }.count)", icon: "person.fill.checkmark", color: .appEmerald)
                    StatCard(title: "In Maintenance", value: "\(fleetVM.vehicles.filter { $0.status == .inMaintenance }.count)", icon: "wrench.fill", color: .orange)
                    StatCard(title: "Ongoing Trips", value: "\(fleetVM.trips.count)", icon: "location.fill", color: .blue)
                }

                .padding(.horizontal)
                
                // Quick Actions (2x2 Grid)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Actions")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ActionCard(title: "Create\nTrip", icon: "map.fill", color: .blue) {
                            showCreateTrip = true
                        }
                        ActionCard(title: "Add\nVehicle", icon: "car.fill", color: .appEmerald) {
                            showAddVehicle = true
                        }
                        ActionCard(title: "Add\nDriver", icon: "person.badge.plus.fill", color: .green) {
                            showAddDriver = true
                        }
                        ActionCard(title: "Add\nMaintenance", icon: "wrench.and.screwdriver.fill", color: .orange) {
                            showAddMaintenanceStaff = true
                        }
                    }
                }
                .padding(.horizontal)
                
                // Quick Links
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Links")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    // Geofencing Link
                    Button(action: {
                        showGeofencing = true
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "map.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.purple)
                                .padding(12)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("View Geofencing")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Manage virtual boundaries")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Analytics Link
                    NavigationLink(destination: FleetManagerAnalyticsView()) {
                        HStack(spacing: 16) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                                .padding(12)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("View Analytics")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Fuel, costs & distance insights")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                }
                
                
                // Activities section
                VStack(spacing: 16) {
                    HStack {
                        Text("Activities")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        NavigationLink(destination: AllActivitiesView().environmentObject(fleetVM)) {
                            Text("See All")
                                .font(.subheadline)
                                .foregroundColor(.appEmerald)
                        }
                    }
                    .padding(.horizontal)
                    
                    if fleetVM.activities.isEmpty {
                        Text("No recent activities.")
                            .foregroundColor(.gray)
                            .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(fleetVM.activities.prefix(3)) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 120) // Bottom spacing for tab bar
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .sheet(isPresented: $showGeofencing) {
            GeofencingView()
        }
    }
    
    var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Fleet Manager")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("Management Dashboard")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                showProfile = true
            }) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.appEmerald)
            }
        }
        .padding(.horizontal)
    }
}

struct ActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20))
                    .padding(10)
                    .background(color.opacity(0.1))
                    .cornerRadius(8)
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.white)
                
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 70) // Fixed minHeight for grid alignment
            .background(Color.appCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .padding(8)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.appSecondaryText)
                    .lineLimit(1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: 110) // Fixed height for equal sizes
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
