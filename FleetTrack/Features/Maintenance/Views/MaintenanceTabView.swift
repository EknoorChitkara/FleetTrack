//
//  MaintenanceTabView.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import SwiftUI

struct MaintenanceTabView: View {
    let user: User
    @State private var selectedTab = 0
    @StateObject private var viewModel: MaintenanceDashboardViewModel
    
    init(user: User) {
        self.user = user
        _viewModel = StateObject(wrappedValue: MaintenanceDashboardViewModel(user: user))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            TabView(selection: $selectedTab) {
                MaintenanceDashboardView(
                    user: user,
                    viewModel: viewModel,
                    selectedTab: $selectedTab
                )
                .tag(0)
                
                TasksView()
                    .tag(1)
                
                AlertsView(alerts: viewModel.alerts)
                    .tag(2)
                
                InventoryView()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .task {
                await viewModel.loadData()
            }
            .onChange(of: selectedTab) { newValue in
                if newValue == 0 {
                    Task {
                        await viewModel.loadData()
                    }
                }
            }
            
            // Floating Tab Bar
            customTabBar
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - Custom Tab Bar
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            MaintenanceTabBarItem(
                icon: "house.fill",
                title: "Dashboard",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            MaintenanceTabBarItem(
                icon: "clipboard.fill",
                title: "Tasks",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }
            
            MaintenanceTabBarItem(
                icon: "bell.fill",
                title: "Alerts",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
            
            MaintenanceTabBarItem(
                icon: "shippingbox.fill",
                title: "Inventory",
                isSelected: selectedTab == 3
            ) {
                selectedTab = 3
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .fill(Color(hexCode: "#2A2A2A").opacity(0.6))
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 15, y: 8)
        .padding(.horizontal, 40)
        .padding(.bottom, 12)
    }
}

// MARK: - Tab Bar Item Component

struct MaintenanceTabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.accentPrimary : AppTheme.textSecondary)
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppTheme.accentPrimary : AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hexCode: "#2A2A2C") : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) tab")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
        .accessibilityIdentifier("maintenance_tab_\(title.lowercased())")
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    MaintenanceTabView(user: .testAdmin())
}
