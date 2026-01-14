//
//  SupabaseClient.swift
//  FleetTrack
//
//  Created by FleetTrack on 08/01/26.
//

import Foundation
import Supabase

/// Custom JSON decoder with ISO 8601 date support for Supabase
private let customDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        
        // Try ISO 8601 with fractional seconds first (e.g., "2022-01-13T10:30:00.000Z")
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Try ISO 8601 without fractional seconds (e.g., "2022-01-13T10:30:00Z")
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Try date-only format (e.g., "2022-01-13")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Cannot decode date string: \(dateString)"
        )
    }
    return decoder
}()

/// Custom JSON encoder with ISO 8601 date support for Supabase
private let customEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
}()

/// Global Supabase client - initialized early to prevent deep link crashes
/// ⚠️ IMPORTANT: Must be outside any View or class for early initialization
let supabase = SupabaseClient(
    supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
    supabaseKey: SupabaseConfig.supabaseAnonKey,
    options: SupabaseClientOptions(
        db: .init(
            encoder: customEncoder,
            decoder: customDecoder
        ),
        auth: .init(emitLocalSessionAsInitialSession: true)
    )
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
