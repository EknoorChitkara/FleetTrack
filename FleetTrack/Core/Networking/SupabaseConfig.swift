//
//  SupabaseConfig.swift
//  FleetTrack
//
//  Created by FleetTrack on 08/01/26.
//

import Foundation
 
/// Supabase configuration constants
enum SupabaseConfig {
    
    // MARK: - Supabase Credentials
    
    /// Your Supabase project URL
    static let supabaseURL = "https://aqvcmemepiupasgozdei.supabase.co"
    
    /// Your Supabase anonymous (public) key
    static let supabaseAnonKey = "sb_publishable_BWUDyIK9C8RxkWgkJhCx5A_34dcG1rT"
    
    // MARK: - Deep Link Configuration
    
    /// URL scheme for the app (MUST match Xcode URL Types exactly, case-sensitive)
    static let urlScheme = "fleettrack"
    
    /// Site URL for Supabase
    /// Dashboard → Authentication → URL Configuration → Site URL
    /// ⚠️ MUST be: fleettrack://auth
    static let siteURL = "fleettrack://auth"
    
    /// Redirect URL for password reset and auth callbacks
    /// Dashboard → Authentication → URL Configuration → Redirect URLs
    /// ⚠️ MUST be: fleettrack://auth/callback
    static let redirectURL = URL(string: "fleettrack://auth/callback")!
    
    // MARK: - Database Tables
    
    /// Table name for user profiles in Supabase
    static let usersTable = "users"
}
