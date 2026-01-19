//
//  MaintenancePersonnelModels.swift
//  FleetTrack
//
//  Created for Fleet Manager - Maintenance Personnel Management
//

import Foundation
import SwiftUI

// MARK: - Maintenance Personnel Model (Matches DB Schema)

struct MaintenancePersonnel: Identifiable, Codable {
    let id: UUID
    var userId: UUID?
    var fullName: String?
    var email: String?
    var phoneNumber: String?
    var specializations: String?  // Changed from [String]? to String? to match DB
    var isActive: Bool?
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fullName = "full_name"
        case email
        case phoneNumber = "phone_number"
        case specializations
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        fullName: String? = nil,
        email: String? = nil,
        phoneNumber: String? = nil,
        specializations: String? = nil,
        isActive: Bool? = true,
        createdAt: Date? = Date(),
        updatedAt: Date? = Date()
    ) {
        self.id = id
        self.userId = userId
        self.fullName = fullName
        self.email = email
        self.phoneNumber = phoneNumber
        self.specializations = specializations
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Convenience computed property for display
    var displayName: String {
        fullName ?? email ?? "Unknown Personnel"
    }
    
    var specializationsDisplay: String {
        specializations ?? "None"
    }
}

// MARK: - Form Data Model

struct MaintenanceCreationData {
    var fullName: String = ""
    var email: String = ""
    var phoneNumber: String = ""
    var specializations: String = ""  // Changed from [String] to String
}
