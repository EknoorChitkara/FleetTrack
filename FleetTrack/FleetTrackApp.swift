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
    
    // Inject ViewModel at root
    @StateObject private var authViewModel = AuthViewModel()
    @State private var passwordResetCode: String?
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        print("✅ Firebase initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let resetCode = passwordResetCode {
                    // Show password reset view
                    PasswordResetView(oobCode: resetCode) {
                        // On success, clear reset code and show login
                        passwordResetCode = nil
                    }
                } else if authViewModel.isAuthenticated {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(authViewModel)
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }
    
    // MARK: - Deep Link Handling
    
    private func handleDeepLink(_ url: URL) {
        let action = DeepLinkHandler.parse(url)
        
        switch action {
        case .passwordReset(let oobCode):
            print("🔗 Password reset deep link received")
            passwordResetCode = oobCode
            
        case .emailVerification(let oobCode):
            print("🔗 Email verification deep link received")
            // Handle email verification if needed
            
        case .unknown:
            print("⚠️ Unknown deep link: \(url)")
        }
    }
}
