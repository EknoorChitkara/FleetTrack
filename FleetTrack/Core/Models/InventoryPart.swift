//
//  InventoryPart.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import Foundation

struct InventoryPart: Identifiable, Codable, Hashable {
    let id: UUID
    var partName: String
    var partNumber: String // SKU/Part Number
    var description: String?
    var currentStock: Int
    var minimumThreshold: Int
    var unitPrice: Double
    var supplier: String?
    var lastRestocked: Date?
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        partName: String,
        partNumber: String,
        description: String? = nil,
        currentStock: Int = 0,
        minimumThreshold: Int = 0,
        unitPrice: Double = 0.0,
        supplier: String? = nil,
        lastRestocked: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.partName = partName
        self.partNumber = partNumber
        self.description = description
        self.currentStock = currentStock
        self.minimumThreshold = minimumThreshold
        self.unitPrice = unitPrice
        self.supplier = supplier
        self.lastRestocked = lastRestocked
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    var isLowStock: Bool {
        currentStock <= minimumThreshold
    }
    
    var formattedPrice: String {
        String(format: "₹%.2f", unitPrice)
    }
}
