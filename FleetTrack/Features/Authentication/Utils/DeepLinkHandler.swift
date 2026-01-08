//
//  DeepLinkHandler.swift
//  FleetTrack
//
//  Created by Firebase Integration
//

import Foundation
import FirebaseAuth

/// Handles Firebase authentication deep links
class DeepLinkHandler {
    
    enum DeepLinkAction {
        case passwordReset(oobCode: String)
        case emailVerification(oobCode: String)
        case unknown
    }
    
    /// Parse Firebase auth action URL
    static func parse(_ url: URL) -> DeepLinkAction {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return .unknown
        }
        
        // Extract mode and oobCode
        let mode = queryItems.first(where: { $0.name == "mode" })?.value
        let oobCode = queryItems.first(where: { $0.name == "oobCode" })?.value
        
        guard let code = oobCode else {
            return .unknown
        }
        
        switch mode {
        case "resetPassword":
            return .passwordReset(oobCode: code)
        case "verifyEmail":
            return .emailVerification(oobCode: code)
        default:
            return .unknown
        }
    }
    
    /// Verify password reset code is valid
    static func verifyPasswordResetCode(_ code: String) async throws -> String {
        return try await Auth.auth().verifyPasswordResetCode(code)
    }
    
    /// Confirm password reset with new password
    static func confirmPasswordReset(code: String, newPassword: String) async throws {
        try await Auth.auth().confirmPasswordReset(withCode: code, newPassword: newPassword)
    }
}
