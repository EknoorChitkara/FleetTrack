//
//  InspectionModels.swift
//  FleetTrack
//
//  Created for Driver App
//

import Foundation
import SwiftUI

// MARK: - Enums

enum InspectionTab: String, CaseIterable {
    case summary = "Summary"
    case checklist = "Checklist"
    case history = "History"
}

enum ServiceType: String, CaseIterable, Identifiable {
    case routineMaintenance = "Routine Maintenance"
    case emergency = "Emergency"
    
    var id: String { rawValue }
}

// MARK: - Models

struct InspectionItem: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    var isChecked: Bool
    
    init(id: UUID = UUID(), name: String, isChecked: Bool = false) {
        self.id = id
        self.name = name
        self.isChecked = isChecked
    }
}

struct ServiceRequest: Identifiable, Hashable {
    let id: UUID
    let serviceType: ServiceType
    let preferredDate: Date
    let notes: String
    let status: ServiceRequestStatus
    let requestDate: Date
    
    init(id: UUID = UUID(), serviceType: ServiceType, preferredDate: Date, notes: String, status: ServiceRequestStatus = .pending, requestDate: Date = Date()) {
        self.id = id
        self.serviceType = serviceType
        self.preferredDate = preferredDate
        self.notes = notes
        self.status = status
        self.requestDate = requestDate
    }
}

enum ServiceRequestStatus: String, Codable {
    case pending = "Pending"
    case approved = "Approved"
    case completed = "Completed"
    case cancelled = "Cancelled"
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .blue
        case .completed: return .green
        case .cancelled: return .gray
        }
    }
}

struct InspectionHistoryRecord: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let date: Date
    let status: String // e.g., "Completed", "Pending"
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, date, status, description
    }
    
    var color: Color {
        switch status {
        case "Completed": return .appEmerald
        case "Pending": return .orange
        default: return .gray
        }
    }
}

// MARK: - Vehicle Inspection Model (for Supabase)

struct VehicleInspection: Identifiable, Codable {
    let id: UUID
    let vehicleId: UUID
    let driverId: UUID
    let inspectionDate: Date
    let checklistItems: [InspectionItem]
    let itemsChecked: Int
    let totalItems: Int
    let allItemsPassed: Bool
    let notes: String?
    let status: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vehicleId = "vehicle_id"
        case driverId = "driver_id"
        case inspectionDate = "inspection_date"
        case checklistItems = "checklist_items"
        case itemsChecked = "items_checked"
        case totalItems = "total_items"
        case allItemsPassed = "all_items_passed"
        case notes
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Mock Data

extension InspectionItem {
    static let defaultChecklist: [InspectionItem] = [
        .init(name: "Tires"),
        .init(name: "Brakes"),
        .init(name: "Lights"),
        .init(name: "Oil"),
        .init(name: "Fuel"),
        .init(name: "Mirrors"),
        .init(name: "Wipers"),
        .init(name: "Horn")
    ]
}

extension InspectionHistoryRecord {
    static let mocks: [InspectionHistoryRecord] = [
        .init(
            id: UUID(),
            title: "Oil Change",
            date: Calendar.current.date(byAdding: .day, value: -20, to: Date())!,
            status: "Completed",
            description: "Regular maintenance"
        ),
        .init(
            id: UUID(),
            title: "Tire Rotation",
            date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
            status: "Completed",
            description: "All tires rotated"
        ),
        .init(
            id: UUID(),
            title: "Brake Inspection",
            date: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
            status: "Completed",
            description: "Brake pads replaced"
        )
    ]
}
