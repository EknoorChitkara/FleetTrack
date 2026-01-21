//
//  RootView.swift
//  FleetTrack
//

import Supabase
import SwiftUI

struct RootView: View {
    @ObservedObject private var sessionManager = SessionManager.shared
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                splashView
                    .transition(.opacity)
            } else {
                mainContent
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Dismiss splash screen after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
    
    private var mainContent: some View {
        ZStack {
            if sessionManager.isLoading {
                loadingView
            } else if sessionManager.isAuthenticated, let user = sessionManager.currentUser {
                // User is authenticated - show dashboard based on role
                NavigationStack {
                    switch user.role {
                    case .fleetManager:
                        FleetManagerDashboardView(user: user)
                    case .driver:
                        DriverDashboardView(user: user).toolbar { logoutButton }
                    case .maintenancePersonnel:
                        MaintenanceTabView(user: user)
                    }
                }
            } else {
                // User is not authenticated - show login page
                LoginView()
            }
        }
    }
    
    private var splashView: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "truck.box.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.appEmerald)
                    .shadow(color: .appEmerald.opacity(0.5), radius: 20)
                
                Text("FleetTrack")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
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
