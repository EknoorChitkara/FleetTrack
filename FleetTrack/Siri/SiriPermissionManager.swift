
//
//  SiriPermissionManager.swift
//  FleetTrack
//
//  Manages permissions for Siri interactions.
//

import AppIntents
import CoreLocation

class SiriPermissionManager {
    static let shared = SiriPermissionManager()
    
    private init() {}
    
    /// Checks if the intent is authorized to execute based on authentication status.
    /// Returns true if authorized, throws an error or returns false otherwise.
    func checkAuthStatus() async throws -> Bool {
        // In a real App Intent, we can't easily access Singelton state if the app is in background/extension mode
        // effectively, but since these are In-App Intents (available iOS 16+), they run in the app process.
        
        guard let _ = try? await SupabaseAuthService.shared.getCurrentUser() else {
            return false
        }
        return true
    }
    
    /// Helper to enforce authentication and throw a dialog if not authenticated.
    func enforceAuth() async throws {
        let isAuthenticated = try await checkAuthStatus()
        guard isAuthenticated else {
            // Throwing an error that AppIntents can catch/display is one way,
            // but often we return a IntentResult with a dialog.
            // Since this is a helper, we'll throw a specific error type.
            throw SiriError.unauthorized
        }
    }
}

enum SiriError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case unauthorized
    case missingData(String)
    case unknown
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .unauthorized:
            return "You need to be logged in to perform this action. Please open the app and log in."
        case .missingData(let item):
            return "I couldn't find any information about \(item)."
        case .unknown:
            return "Something went wrong."
        }
    }
}
