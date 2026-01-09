//
//  SupabaseClient.swift
//  FleetTrack
//
//  Created by FleetTrack on 08/01/26.
//

import Foundation
import Supabase

/// Global Supabase client - initialized early to prevent deep link crashes
/// ⚠️ IMPORTANT: Must be outside any View or class for early initialization
let supabase = SupabaseClient(
    supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
    supabaseKey: SupabaseConfig.supabaseAnonKey
)

/// Singleton wrapper for accessing the global Supabase client
final class SupabaseClientManager: @unchecked Sendable {
    
    // MARK: - Singleton
    
    static let shared = SupabaseClientManager()
    
    // MARK: - Properties
    
    /// The global Supabase client instance
    var client: SupabaseClient {
        return supabase
    }
    
    // MARK: - Initialization
    
    private init() {
        print("✅ Supabase client initialized with URL: \(SupabaseConfig.supabaseURL)")
    }
}
