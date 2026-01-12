//
//  FleetTrackApp.swift
//  FleetTrack
//
//  Created by Eknoor on 07/01/26.
//

import SwiftUI
import Supabase


@main
struct FleetTrackApp: App {
    @StateObject private var sessionManager = SessionManager.shared
    @State private var deepLinkData: DeepLinkData?
    
    
    struct DeepLinkData: Identifiable {
        let id = UUID()
        let url: URL
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if sessionManager.isAuthenticated, let user = sessionManager.currentUser {
                    NavigationStack {
                        switch user.role {
                        case .fleetManager:
                            FleetManagerDashboardView(user: user)
                        case .driver:
                            DriverDashboardView(user: user)
                        case .maintenancePersonnel:
                            MaintenanceDashboardView(user: user)
                        }
                    }
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .sheet(item: $deepLinkData) { data in
                        ResetPasswordView(url: data.url)
                    }
                } else {
                    LoginView()
                }
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        print(" App opened via deep link: \(url.absoluteString)")
        
        // Use Identifiable item to ensure URL is present when sheet opens
        self.deepLinkData = DeepLinkData(url: url)
    }
}
