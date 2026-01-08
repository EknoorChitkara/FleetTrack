//
//  Part.swift
//  FleetTrack
//
//  Created by FleetTrack on 08/01/26.
//

import Foundation

enum PartCategory: String, Codable, CaseIterable {
    case engine = "Engine"
    case transmission = "Transmission"
    case brakes = "Brakes"
    case suspension = "Suspension"
    case electrical = "Electrical"
    case bodyWork = "Body Work"
    case tires = "Tires"
    case fluids = "Fluids"
    case filters = "Filters"
    case other = "Other"
}

struct Part: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var partNumber: String
    var category: PartCategory
    var description: String?
    
    // Inventory tracking
    var quantityInStock: Int
    var minimumStockLevel: Int
    var unitPrice: Double
    
    // Supplier info
    var supplierName: String?
    var supplierContact: String?
    
    // Additional metadata
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        partNumber: String,
        category: PartCategory,
        description: String? = nil,
        quantityInStock: Int,
        minimumStockLevel: Int,
        unitPrice: Double,
        supplierName: String? = nil,
        supplierContact: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.partNumber = partNumber
        self.category = category
        self.description = description
        self.quantityInStock = quantityInStock
        self.minimumStockLevel = minimumStockLevel
        self.unitPrice = unitPrice
        self.supplierName = supplierName
        self.supplierContact = supplierContact
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Computed properties
    var isLowStock: Bool {
        quantityInStock <= minimumStockLevel
    }
    
    var stockStatus: String {
        if quantityInStock == 0 {
            return "Out of Stock"
        } else if isLowStock {
            return "Low Stock"
        } else {
            return "In Stock"
        }
    }
    
    var formattedPrice: String {
        String(format: "₹%.2f", unitPrice)
    }
}

// MARK: - Mock Data
extension Part {
    static let mockPart1 = Part(
        name: "Engine Oil Filter",
        partNumber: "EF-001",
        category: .filters,
        description: "High-quality oil filter for diesel engines",
        quantityInStock: 25,
        minimumStockLevel: 10,
        unitPrice: 450.00,
        supplierName: "Auto Parts Inc.",
        supplierContact: "+91 98765 00001"
    )
    
    static let mockPart2 = Part(
        name: "Brake Pads (Set)",
        partNumber: "BP-102",
        category: .brakes,
        description: "Front brake pads for light commercial vehicles",
        quantityInStock: 8,
        minimumStockLevel: 15,
        unitPrice: 2500.00,
        supplierName: "Brake Masters",
        supplierContact: "+91 98765 00002"
    )
    
    static let mockPart3 = Part(
        name: "Air Filter",
        partNumber: "AF-203",
        category: .filters,
        description: "Engine air filter",
        quantityInStock: 0,
        minimumStockLevel: 5,
        unitPrice: 650.00,
        supplierName: "Filter World",
        supplierContact: "+91 98765 00003"
    )
    
    static let mockPart4 = Part(
        name: "Headlight Assembly",
        partNumber: "HL-305",
        category: .electrical,
        description: "LED headlight assembly",
        quantityInStock: 12,
        minimumStockLevel: 5,
        unitPrice: 3500.00,
        supplierName: "Auto Parts Inc.",
        supplierContact: "+91 98765 00001"
    )
    
    static let mockParts: [Part] = [
        mockPart1,
        mockPart2,
        mockPart3,
        mockPart4
    ]
}
