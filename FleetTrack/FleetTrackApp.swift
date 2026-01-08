//
//  FleetTrackApp.swift
//  FleetTrack
//
//  Created by Eknoor on 07/01/26.
//

import SwiftUI
import FirebaseCore

@main
struct FleetTrackApp: App {
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        print("✅ Firebase initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
