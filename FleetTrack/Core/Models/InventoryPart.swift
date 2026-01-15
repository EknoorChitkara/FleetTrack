//
//  InventoryPart.swift
//  FleetTrack
//
//  Updated to match database `parts` table schema
//

import Foundation

// MARK: - Part Category

struct PartCategory: Codable, Hashable, Identifiable {
    let id: String
    let rawValue: String
    
    init(id: String, rawValue: String) {
        self.id = id
        self.rawValue = rawValue
    }
    
    // Predefined categories
    static let engine = PartCategory(id: "engine", rawValue: "Engine")
    static let transmission = PartCategory(id: "transmission", rawValue: "Transmission")
    static let brakes = PartCategory(id: "brakes", rawValue: "Brakes")
    static let suspension = PartCategory(id: "suspension", rawValue: "Suspension")
    static let electrical = PartCategory(id: "electrical", rawValue: "Electrical")
    static let bodyWork = PartCategory(id: "bodyWork", rawValue: "Body Work")
    static let tires = PartCategory(id: "tires", rawValue: "Tires")
    static let fluids = PartCategory(id: "fluids", rawValue: "Fluids")
    static let filters = PartCategory(id: "filters", rawValue: "Filters")
    static let other = PartCategory(id: "other", rawValue: "Other")
    
    static let predefinedCategories: [PartCategory] = [
        .engine, .transmission, .brakes, .suspension, .electrical,
        .bodyWork, .tires, .fluids, .filters, .other
    ]
    
    // Create custom category
    static func custom(_ name: String) -> PartCategory {
        let id = name.lowercased().replacingOccurrences(of: " ", with: "_")
        return PartCategory(id: id, rawValue: name)
    }
}

// MARK: - InventoryPart Model (Matches DB `parts` table)

struct InventoryPart: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var partNumber: String
    var category: PartCategory
    var description: String?
    var quantityInStock: Int
    var minimumStockLevel: Int
    var unitPrice: Double
    var supplierName: String?
    var supplierContact: String?
    var isActive: Bool
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case partNumber = "part_number"
        case category
        case description
        case quantityInStock = "quantity_in_stock"
        case minimumStockLevel = "minimum_stock_level"
        case unitPrice = "unit_price"
        case supplierName = "supplier_name"
        case supplierContact = "supplier_contact"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        partNumber: String,
        category: PartCategory = .other,
        description: String? = nil,
        quantityInStock: Int = 0,
        minimumStockLevel: Int = 5,
        unitPrice: Double = 0.0,
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
    
    // MARK: - Computed Properties
    
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
extension InventoryPart {
    static let mockPart1 = InventoryPart(
        name: "Oil Filter",
        partNumber: "OF-001",
        category: .filters,
        description: "High quality oil filter for commercial vehicles",
        quantityInStock: 25,
        minimumStockLevel: 10,
        unitPrice: 450.0,
        supplierName: "AutoParts India",
        supplierContact: "+91 98765 43210"
    )
    
    static let mockPart2 = InventoryPart(
        name: "Brake Pads Set",
        partNumber: "BP-002",
        category: .brakes,
        description: "Heavy duty brake pads for trucks",
        quantityInStock: 8,
        minimumStockLevel: 10,
        unitPrice: 2500.0,
        supplierName: "Brake Masters",
        supplierContact: "+91 98765 11111"
    )
    
    static let mockPart3 = InventoryPart(
        name: "Engine Oil 15W-40",
        partNumber: "EO-003",
        category: .fluids,
        description: "Premium diesel engine oil - 5L",
        quantityInStock: 50,
        minimumStockLevel: 20,
        unitPrice: 1800.0,
        supplierName: "Castrol Distributor",
        supplierContact: "+91 98765 22222"
    )
    
    static let mockParts: [InventoryPart] = [
        mockPart1,
        mockPart2,
        mockPart3
    ]
}
