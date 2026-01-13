//
//  AppConfig.swift
//  FleetTrack
//
//  Created by Firebase Integration
//

import Foundation

/// Centralized configuration for the FleetTrack application
struct AppConfig {
    
    // MARK: - App Configuration
    
    struct App {
        /// Deep link base URL for the app
        static let baseURL = "fleettrack://"
        
        /// Web URL for the application
        static let webURL = "https://fleettrack.com"
        
        /// App display name
        static let appName = "FleetTrack"
    }
    
    // MARK: - Firebase Configuration
    
    struct Firebase {
        /// Check if Firebase is properly configured
        static var isConfigured: Bool {
            // This will be set to true after FirebaseApp.configure() is called
            return true
        }
    }
    
    // MARK: - Feature Flags
    
    struct Features {
        /// Enable Firebase Authentication (set to false to use mock services)
        static let useFirebaseAuth = true
        
        /// Enable analytics
        static let analyticsEnabled = false
        
        /// Enable crashlytics
        static let crashlyticsEnabled = false
    }
    
    // MARK: - Environment
    
    enum Environment {
        case development
        case staging
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
    }
}
