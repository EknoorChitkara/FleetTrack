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
    @State private var deepLinkData: DeepLinkData?
    @State private var currentUser: User?
    @State private var isLoggedIn = false
    @State private var isCheckingSession = true
    
    struct DeepLinkData: Identifiable {
        let id = UUID()
        let url: URL
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isCheckingSession {
                    // Loading / Splash Screen
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
                } else if isLoggedIn, let user = currentUser {
                    NavigationStack {
                        switch user.role {
                        case .fleetManager: FleetManagerDashboardView(user: user).toolbar { logoutButton }
                        case .driver: DriverDashboardView(user: user).toolbar { logoutButton }
                        case .maintenancePersonnel: MaintenanceDashboardView(user: user).toolbar { logoutButton }
                        }
                    }
                } else {
                    LoginView(isLoggedIn: $isLoggedIn, currentUser: $currentUser)
                }
            }
            .task {
                await checkSession()
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .sheet(item: $deepLinkData) { data in
                ResetPasswordView(url: data.url)
            }
        }
    }
    
    private func checkSession() async {
        do {
            // 1. Try to get the current session from Supabase
            // Supabase client handles local persistence automatically (Keychain/UserDefaults)
            let session = try await supabase.auth.session
            print(" Found existing session for: \(session.user.email ?? "unknown")")
            
            // 2. Fetch the full user profile from the database
            let userProfile: User = try await supabase.database
                .from("users")
                .select()
                .eq("id", value: session.user.id)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.currentUser = userProfile
                self.isLoggedIn = true
                self.isCheckingSession = false
            }
        } catch {
            print("ℹ️ No active session found or error fetching profile: \(error.localizedDescription)")
            await MainActor.run {
                self.isCheckingSession = false
            }
        }
    }
    
    private var logoutButton: ToolbarItem<(), Button<some View>> {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Task {
                    try? await supabase.auth.signOut()
                    isLoggedIn = false
                    currentUser = nil
                }
            } label: {
                Text("Logout")
                    .foregroundColor(.appEmerald)
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        print(" App opened via deep link: \(url.absoluteString)")
        
        // Use Identifiable item to ensure URL is present when sheet opens
        self.deepLinkData = DeepLinkData(url: url)
    }
}
