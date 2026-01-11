//
//  MaintenanceTabView.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import SwiftUI

struct MaintenanceTabView: View {
    @State private var selectedTab = 0
    @StateObject private var viewModel = MaintenanceDashboardViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            TabView(selection: $selectedTab) {
                MaintenanceDashboardView(
                    viewModel: viewModel,
                    selectedTab: $selectedTab
                )
                .tag(0)
                
                TasksView()
                    .tag(1)
                
                AlertsView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Floating Tab Bar
            customTabBar
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - Custom Tab Bar
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            TabBarItem(
                icon: "house.fill",
                title: "Dashboard",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            TabBarItem(
                icon: "clipboard.fill",
                title: "Tasks",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }
            
            TabBarItem(
                icon: "bell.fill",
                title: "Alerts",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .fill(Color(hex: "#2A2A2A").opacity(0.6))
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 15, y: 8)
        .padding(.horizontal, 60)
        .padding(.bottom, 12)
    }
}

// MARK: - Tab Bar Item Component

struct TabBarItem: View {
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
                    .fill(isSelected ? Color(hex: "#2A2A2C") : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    MaintenanceTabView()
}
