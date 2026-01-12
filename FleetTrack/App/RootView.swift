//
//  RootView.swift
//  FleetTrack
//

import SwiftUI
import Supabase

struct RootView: View {
    @ObservedObject private var sessionManager = SessionManager.shared
    
    var body: some View {
        ZStack {
            // Priority 1: Loading
            if sessionManager.isLoading {
                loadingView
            }
            // Priority 2: Authenticated & User Data Present
            else if sessionManager.isAuthenticated, let user = sessionManager.currentUser {
                NavigationStack {
                    switch user.role {
                    case .fleetManager:
                        FleetManagerDashboardView(user: user).toolbar { logoutButton }
                    case .driver:
                        DriverDashboardView(user: user).toolbar { logoutButton }
                    case .maintenancePersonnel:
                        MaintenanceTabView(user: user)
                    }
                }
            }
            // Priority 3: Not Authenticated (Login)
            else {
                LoginView()
            }
        }
    }
    
    private var loadingView: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.appEmerald)
                    .shadow(color: .appEmerald.opacity(0.3), radius: 10)
                
                ProgressView()
                    .tint(.appEmerald)
            }
        }
    }
    
    private var logoutButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Task {
                    try? await SupabaseAuthService.shared.logout()
                    sessionManager.clearSession()
                }
            } label: {
                Text("Logout")
                    .foregroundColor(.appEmerald)
            }
        }
    }
}
