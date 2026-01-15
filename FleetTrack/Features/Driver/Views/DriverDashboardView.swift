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
    @State private var tripToStart: Trip?
    
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
            DriverCustomTabBar(selectedTab: $selectedTab)
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadDashboardData(user: localUser)
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == 0 {
                Task {
                    await viewModel.loadDashboardData(user: localUser)
                }
            }
        }
        .sheet(isPresented: $isShowingProfile) {
            if let driver = viewModel.driver {
                ProfileView(user: $localUser, driver: .constant(driver))
            } else {
                ProgressView()
                    .padding()
            }
        }
        .fullScreenCover(item: $tripToStart, onDismiss: {
            Task {
                await viewModel.loadDashboardData(user: localUser)
            }
        }) { trip in
            NavigationStack {
                TripMapView(trip: trip)
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
                        Text("Welcome, \(localUser.name.components(separatedBy: " ").first ?? localUser.name)!")
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
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
                    // Active Ongoing Trip Card (High Priority)
                    if let ongoingTrip = viewModel.ongoingTrip {
                        ActiveTripCard(trip: ongoingTrip) {
                            tripToStart = ongoingTrip
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    // Scheduled Upcoming Trip Card (if no ongoing trip)
                    else if let upcomingTrip = viewModel.upcomingTrip {
                        ScheduledTripCard(trip: upcomingTrip) {
                            tripToStart = upcomingTrip
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    
                    // Stat Cards
                    HStack(spacing: 16) {
                        DriverStatCard(
                            title: "Trips Completed",
                            value: "\(viewModel.completedTripsCount)",
                            unit: ""
                        )
                        
                        DriverStatCard(
                            title: "Distance",
                            value: "\(Int(viewModel.totalDistance))",
                            unit: "km"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Performance Metrics (Animated Category Chart)
                    PerformanceMetricsChart(
                        onTimeRate: viewModel.driver?.onTimeDeliveryRate ?? 0,
                        avgSpeed: viewModel.avgSpeed,
                        avgTripDist: viewModel.avgTripDistance
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
                    .padding(.horizontal)
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
