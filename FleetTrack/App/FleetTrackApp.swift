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
    
    struct DeepLinkData: Identifiable {
        let id = UUID()
        let url: URL
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                // Intercept Supabase Auth URLs
                Task {
                    try? await SupabaseClientManager.shared.client.handle(url)
                }
                handleDeepLink(url)
            }
            .sheet(item: $deepLinkData) { data in
                ResetPasswordView(url: data.url)
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        self.deepLinkData = DeepLinkData(url: url)
    }
}
