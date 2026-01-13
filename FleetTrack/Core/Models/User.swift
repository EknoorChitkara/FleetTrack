//
//  User.swift
//  FleetTrack
//
//  Created by FleetTrack on 08/01/26.
//

import Foundation

enum UserRole: String, Codable, CaseIterable {
    case fleetManager = "Fleet Manager"
    case driver = "Driver"
    case maintenancePersonnel = "Maintenance Personnel"
}

struct User: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var email: String
    var phoneNumber: String?
    var role: UserRole
    var profileImageURL: String?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    var employeeID: String? // Added for Driver Auth
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phoneNumber = "phone_number"
        case role
        case profileImageURL = "profile_image_url"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case employeeID = "employee_id"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        email: String,
        phoneNumber: String? = nil,
        role: UserRole,
        profileImageURL: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        employeeID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.role = role
        self.profileImageURL = profileImageURL
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.employeeID = employeeID
    }
    
    // Computed property for initials (for avatar display)
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.count > 1 ? components.last?.first?.uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
}

// MARK: - Mock Data
extension User {
    static let mockFleetManager = User(
        name: "Amit Sharma",
        email: "amit.sharma@fleettrack.com",
        phoneNumber: "+91 98765 43210",
        role: .fleetManager
    )
    
    static let mockDriver = User(
        name: "Rajesh Kumar",
        email: "rajesh.kumar@fleettrack.com",
        phoneNumber: "+91 98765 43210",
        role: .driver
    )
    
    static let mockMaintenancePersonnel = User(
        name: "Priya Singh",
        email: "priya.singh@fleettrack.com",
        phoneNumber: "+91 98765 43211",
        role: .maintenancePersonnel
    )
    
    static let mockUsers: [User] = [
        mockFleetManager,
        mockDriver,
        mockMaintenancePersonnel
    ]
    
    static func testAdmin() -> User {
        return User(
            name: "Admin User",
            email: "admin@fleettrack.com",
            phoneNumber: "+91 98765 00000",
            role: .fleetManager
        )
    }
}
