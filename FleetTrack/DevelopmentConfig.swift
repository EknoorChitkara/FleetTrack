//
//  DevelopmentConfig.swift
//  FleetTrack
//
//  Development-only configuration for testing and debugging
//

import Foundation

/// Development configuration flags
/// 
/// To revert to normal login flow:
/// - Set `bypassLogin` to `false`
/// - Or delete/rename this file
struct DevelopmentConfig {
    /// Set to `true` to skip login and go directly to the dashboard
    /// Set to `false` to restore normal login flow
    static let bypassLogin = false
    
    /// The role to use when bypassing login
    /// Options: .fleetManager, .driver, .maintenancePersonnel
    static let defaultRole: UserRole = .maintenancePersonnel
    
    /// Mock user to use when bypassing login
    static let mockUser = User(
        name: "Test User",
        email: "test@fleettrack.com",
        phoneNumber: "+91 98765 00000",
        role: defaultRole
    )
}
