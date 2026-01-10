//
//  DriverDashboardView.swift
//  FleetTrack
//

import SwiftUI

struct DriverDashboardView: View {
    @State private var localUser: User
    @StateObject private var viewModel = DriverDashboardViewModel()
    @State private var selectedTab = 0
    @State private var isShowingProfile = false
    
    init(user: User) {
        self._localUser = State(initialValue: user)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()
            
            // Content switching based on tab
            Group {
                switch selectedTab {
                case 0:
                    dashboardContent
                case 1:
                    DriverTripsView()
                case 2:
                    DriverAlertsView()
                default:
                    dashboardContent
                }
            }
            
            // Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadDashboardData(user: localUser)
        }
        .sheet(isPresented: $isShowingProfile) {
            if let driver = viewModel.driver {
                ProfileView(user: $localUser, driver: .constant(driver))
            } else {
                ProgressView()
                    .padding()
            }
        }
    }
    
    // Extracted dashboard content
    private var dashboardContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Driver Dashboard")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Welcome back, \(localUser.name.components(separatedBy: " ").first ?? localUser.name)!")
                            .font(.subheadline)
                            .foregroundColor(.appSecondaryText)
                    }
                    
                    Spacer()
                    
                    Button {
                        isShowingProfile = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.8))
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.appEmerald)
                        .padding(.top, 100)
                } else {
                    // Stat Cards
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Trips Completed",
                            value: "\(viewModel.driver?.totalTrips ?? 0)",
                            unit: ""
                        )
                        
                        StatCard(
                            title: "Distance",
                            value: "\(Int(viewModel.driver?.totalDistanceDriven ?? 0))",
                            unit: "km"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Performance Metrics
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Performance Metrics")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        MetricRow(
                            title: "On-Time Delivery",
                            value: "\(Int(viewModel.driver?.onTimeDeliveryRate ?? 0))%",
                            progress: (viewModel.driver?.onTimeDeliveryRate ?? 0) / 100.0
                        )
                        
                        MetricRow(
                            title: "Safety Score",
                            value: "\(viewModel.driver?.formattedRating ?? "0.0")/5.0",
                            progress: (viewModel.driver?.rating ?? 0) / 5.0
                        )
                        
                        MetricRow(
                            title: "Fuel Efficiency",
                            value: "\(String(format: "%.1f", viewModel.driver?.fuelEfficiency ?? 0.0)) L/100km",
                            progress: (viewModel.driver?.fuelEfficiency ?? 0.0) > 0 ? 0.7 : 0.0
                        )
                    }
                    .padding()
                    .background(Color.appCardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Assigned Vehicle
                    AssignedVehicleCard(vehicle: viewModel.assignedVehicle)
                        .padding(.horizontal)
                    
                    // Recent Trips
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Trips")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if viewModel.recentTrips.isEmpty {
                            Text("No recent trips")
                                .font(.subheadline)
                                .foregroundColor(.appSecondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(viewModel.recentTrips) { trip in
                                RecentTripRow(trip: trip)
                                
                                if trip.id != viewModel.recentTrips.last?.id {
                                    Divider().background(Color.white.opacity(0.1))
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.appCardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                    .padding(.bottom, 100) // Space for TabBar
                }
            }
        }
        .refreshable {
            await viewModel.loadDashboardData(user: localUser)
        }
    }

}

// MARK: - Preview
#Preview {
    DriverDashboardView(user: .mockDriver)
}
