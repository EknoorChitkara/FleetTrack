
//
//  SiriRoleResolver.swift
//  FleetTrack
//
//  Resolves the current user's role for Siri commands.
//

import Foundation

class SiriRoleResolver {
    static let shared = SiriRoleResolver()
    
    private init() {}
    
    /// Returns the current user's role.
    func getCurrentRole() async -> UserRole? {
        // Reuse the Auth service to get user
        guard let user = try? await SupabaseAuthService.shared.getCurrentUser() else {
            return nil
        }
        return user.role
    }
    
    /// Verifies if the user has the required role.
    func requireRole(_ role: UserRole) async throws {
        guard let currentRole = await getCurrentRole() else {
            throw SiriError.unauthorized
        }
        
        guard currentRole == role else {
            throw SiriError.unauthorized
        }
    }
    
    /// Verifies if the user has any of the required roles.
    func requireAnyRole(_ roles: [UserRole]) async throws {
        guard let currentRole = await getCurrentRole() else {
            throw SiriError.unauthorized
        }
        
        guard roles.contains(currentRole) else {
            throw SiriError.unauthorized
        }
    }
}
