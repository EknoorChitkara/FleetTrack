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
    @State private var isShowingInspection = false // New state
    @State private var isShowingReportIssue = false // New state
    
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
                case 3:
                    if let driver = viewModel.driver {
                        ProfileView(user: $localUser, driver: .constant(driver))
                    } else {
                        ProgressView().tint(.appEmerald).padding(.top, 100)
                    }
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
            } else if newValue == 3 {
                // Profile View Tab
                if viewModel.driver == nil {
                    Task {
                        await viewModel.loadDashboardData(user: localUser)
                    }
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
                // Slight delay to ensure DB propagation and UI transition smoothness
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                await viewModel.loadDashboardData(user: localUser)
            }
        }) { trip in
            NavigationStack {
                TripMapView(
                    trip: trip,
                    driverName: localUser.name,
                    vehicleInfo: viewModel.assignedVehicle.map { "\($0.manufacturer) \($0.model) (\($0.registrationNumber))" } ?? "Unassigned Vehicle"
                )
            }
        }
        .fullScreenCover(isPresented: $isShowingInspection) {
            DriverVehicleInspectionView(viewModel: VehicleInspectionViewModel(vehicle: viewModel.assignedVehicle))
        }
        .fullScreenCover(isPresented: $isShowingReportIssue) {
            ReportIssueView(vehicle: viewModel.assignedVehicle)
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
                            .font(.appTitle)
                            .foregroundColor(.white)
                            .accessibilityAddTraits(.isHeader)
                    }
                    
                    Spacer()
                    
                    Button {
                        HapticManager.shared.triggerSelection()
                        isShowingProfile = true
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.appEmerald)
                    }
                    .accessibilityLabel("Profile and Settings")
                    .accessibilityIdentifier("driver_profile_button")
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                if viewModel.isLoading && viewModel.driver == nil {
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
                        DriverStatCard(
                            title: "Trips Completed",
                            value: "\(viewModel.completedTripsCount)",
                            unit: ""
                        )
                        .accessibilityIdentifier("driver_stat_completed_trips")
                        
                        DriverStatCard(
                            title: "Distance",
                            value: "\(Int(viewModel.totalDistance))",
                            unit: "km"
                        )
                        .accessibilityIdentifier("driver_stat_total_distance")
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
                    
                    // Dashboard Actions (Inspection, Report Issue)
                    VStack(spacing: 12) {
                        ForEach(viewModel.dashboardActions) { action in
                            DashboardActionCard(action: action) {
                                HapticManager.shared.triggerImpact(style: .light)
                                if action.type == .vehicleInspection {
                                    isShowingInspection = true
                                } else if action.type == .reportIssue {
                                    isShowingReportIssue = true
                                } else {
                                    // Handle other actions or show "Coming Soon"
                                    print("Tapped action: \(action.title)")
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(action.title), \(action.subtitle)")
                            .accessibilityHint("Double tap to \(action.title.lowercased())")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Trips
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Trips")
                            .font(.appHeadline)
                            .foregroundColor(.white)
                            .accessibilityAddTraits(.isHeader)
                        
                        if viewModel.recentTrips.isEmpty {
                            Text("No recent trips")
                                .font(.subheadline)
                                .foregroundColor(.appSecondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(viewModel.recentTrips) { trip in
                                RecentTripRow(trip: trip)
                                    .accessibilityIdentifier("driver_recent_trip_\(trip.id.uuidString.prefix(8))")
                                
                                if trip.id != viewModel.recentTrips.last?.id {
                                    Divider().background(Color.white.opacity(0.1))
                                }
                            }
                        }
                    }
                    .accessibilityIdentifier("driver_recent_trips_list")
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
