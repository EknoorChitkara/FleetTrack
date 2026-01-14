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
    @State private var navigateToInspection = false
    @State private var navigateToReportIssue = false
    @State private var initialInspectionTab: InspectionTab = .summary
    
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
                        DriverStatCard(
                            title: "Trips Completed",
                            value: "\(viewModel.driver?.totalTrips ?? 0)",
                            unit: ""
                        )
                        
                        DriverStatCard(
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
                    
                    // Quick Actions
                    VStack(spacing: 16) {
                        DashboardActionRow(
                            icon: "car.fill",
                            title: "Vehicle Inspection",
                            subtitle: "Daily checklist & maintenance",
                            action: {
                                initialInspectionTab = .summary
                                navigateToInspection = true
                            }
                        )
                        
                        DashboardActionRow(
                            icon: "exclamationmark.triangle.fill",
                            title: "Report Issue",
                            subtitle: "Emergency or maintenance alert",
                            action: {
                                navigateToReportIssue = true
                            }
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Space for TabBar
                    
                    // Hidden Navigation Links
                    NavigationLink(isActive: $navigateToInspection) {
                        DriverVehicleInspectionView(user: localUser, initialTab: initialInspectionTab)
                    } label: {
                        EmptyView()
                    }
                    
                    NavigationLink(isActive: $navigateToReportIssue) {
                        ReportIssueView(driverId: localUser.id, vehicleId: viewModel.assignedVehicle?.id)
                    } label: {
                        EmptyView()
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadDashboardData(user: localUser)
        }
    }
}

// MARK: - Components

struct DashboardActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.appSecondaryText)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.appSecondaryText)
            }
            .padding(16)
            .background(Color.appCardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
}


// MARK: - Preview
#Preview {
    DriverDashboardView(user: .mockDriver)
}
