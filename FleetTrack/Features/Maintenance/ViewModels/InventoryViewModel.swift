//
//  InventoryViewModel.swift
//  FleetTrack
//
//  Created for Inventory Management
//

import Foundation
import SwiftUI
import Combine

class InventoryViewModel: ObservableObject {
    @Published var parts: [InventoryPart] = []
    @Published var searchText: String = ""
    @Published var customCategories: [PartCategory] = []
    
    init() {
        // Initialize with some mock data
        self.parts = [
            // Engine Parts
            InventoryPart(
                name: "Oil Filter",
                partNumber: "OF-001",
                category: .filters,
                description: "High quality oil filter for commercial vehicles",
                quantityInStock: 25,
                minimumStockLevel: 10,
                unitPrice: 450.0,
                supplierName: "AutoParts India",
                supplierContact: "+91 98765 43210"
            ),
            InventoryPart(
                name: "Air Filter",
                partNumber: "AF-002",
                category: .filters,
                description: "High efficiency air filter",
                quantityInStock: 3,
                minimumStockLevel: 10,
                unitPrice: 350.0,
                supplierName: "AutoParts India",
                supplierContact: "+91 98765 43210"
            ),
            InventoryPart(
                name: "Spark Plugs Set",
                partNumber: "SP-003",
                category: .engine,
                description: "Set of 4 spark plugs",
                quantityInStock: 15,
                minimumStockLevel: 8,
                unitPrice: 800.0,
                supplierName: "Engine Parts Co.",
                supplierContact: "+91 98765 55555"
            ),
            
            // Brake Components
            InventoryPart(
                name: "Brake Pads Set",
                partNumber: "BP-004",
                category: .brakes,
                description: "Heavy duty brake pads for trucks",
                quantityInStock: 4,
                minimumStockLevel: 10,
                unitPrice: 2500.0,
                supplierName: "Brake Masters",
                supplierContact: "+91 98765 11111"
            ),
            InventoryPart(
                name: "Brake Rotors",
                partNumber: "BR-005",
                category: .brakes,
                description: "Front brake rotors - pair",
                quantityInStock: 12,
                minimumStockLevel: 6,
                unitPrice: 3500.0,
                supplierName: "Brake Masters",
                supplierContact: "+91 98765 11111"
            ),
            InventoryPart(
                name: "Brake Fluid DOT 4",
                partNumber: "BF-006",
                category: .fluids,
                description: "High performance brake fluid - 1L",
                quantityInStock: 18,
                minimumStockLevel: 10,
                unitPrice: 450.0,
                supplierName: "Castrol Distributor",
                supplierContact: "+91 98765 22222"
            ),
            
            // Electrical
            InventoryPart(
                name: "Battery 12V",
                partNumber: "BAT-007",
                category: .electrical,
                description: "Heavy duty 12V battery",
                quantityInStock: 8,
                minimumStockLevel: 5,
                unitPrice: 5500.0,
                supplierName: "Exide Dealer",
                supplierContact: "+91 98765 33333"
            ),
            InventoryPart(
                name: "Alternator",
                partNumber: "ALT-008",
                category: .electrical,
                description: "Replacement alternator",
                quantityInStock: 3,
                minimumStockLevel: 3,
                unitPrice: 8500.0,
                supplierName: "Electrical Parts Ltd",
                supplierContact: "+91 98765 44444"
            ),
            
            // Tires
            InventoryPart(
                name: "Truck Tire 10R22.5",
                partNumber: "TT-009",
                category: .tires,
                description: "Commercial truck tire",
                quantityInStock: 16,
                minimumStockLevel: 12,
                unitPrice: 12000.0,
                supplierName: "MRF Distributor",
                supplierContact: "+91 98765 66666"
            ),
            
            // Fluids & Oils
            InventoryPart(
                name: "Engine Oil 15W-40",
                partNumber: "EO-010",
                category: .fluids,
                description: "Premium diesel engine oil - 5L",
                quantityInStock: 50,
                minimumStockLevel: 20,
                unitPrice: 1800.0,
                supplierName: "Castrol Distributor",
                supplierContact: "+91 98765 22222"
            ),
            InventoryPart(
                name: "Transmission Fluid",
                partNumber: "TF-011",
                category: .fluids,
                description: "Automatic transmission fluid - 4L",
                quantityInStock: 6,
                minimumStockLevel: 10,
                unitPrice: 2200.0,
                supplierName: "Shell Distributor",
                supplierContact: "+91 98765 77777"
            ),
            InventoryPart(
                name: "Coolant/Antifreeze",
                partNumber: "CL-012",
                category: .fluids,
                description: "Engine coolant - 5L",
                quantityInStock: 20,
                minimumStockLevel: 15,
                unitPrice: 650.0,
                supplierName: "Castrol Distributor",
                supplierContact: "+91 98765 22222"
            ),
            
            // Suspension
            InventoryPart(
                name: "Shock Absorbers",
                partNumber: "SA-013",
                category: .suspension,
                description: "Heavy duty shock absorbers - pair",
                quantityInStock: 0,
                minimumStockLevel: 4,
                unitPrice: 4500.0,
                supplierName: "Suspension Parts Co.",
                supplierContact: "+91 98765 88888"
            ),
            
            // Transmission
            InventoryPart(
                name: "Clutch Kit",
                partNumber: "CK-014",
                category: .transmission,
                description: "Complete clutch kit",
                quantityInStock: 5,
                minimumStockLevel: 3,
                unitPrice: 7500.0,
                supplierName: "Transmission Experts",
                supplierContact: "+91 98765 99999"
            ),
            
            // Body Work
            InventoryPart(
                name: "Side Mirror",
                partNumber: "SM-015",
                category: .bodyWork,
                description: "Driver side mirror",
                quantityInStock: 0,
                minimumStockLevel: 2,
                unitPrice: 1200.0,
                supplierName: "Body Parts Supply",
                supplierContact: "+91 98765 00000"
            ),
            InventoryPart(
                name: "Headlight Assembly",
                partNumber: "HL-016",
                category: .bodyWork,
                description: "LED headlight assembly",
                quantityInStock: 0,
                minimumStockLevel: 4,
                unitPrice: 3200.0,
                supplierName: "Body Parts Supply",
                supplierContact: "+91 98765 00000"
            )
        ]
    }
    
    // MARK: - Computed Properties
    
    var totalItems: Int {
        parts.count
    }
    
    var lowStockParts: [InventoryPart] {
        parts.filter { $0.isLowStock && $0.quantityInStock > 0 }
    }
    
    var outOfStockParts: [InventoryPart] {
        parts.filter { $0.quantityInStock == 0 }
    }
    
    var filteredParts: [InventoryPart] {
        if searchText.isEmpty {
            return parts
        }
        return parts.filter { part in
            part.name.localizedCaseInsensitiveContains(searchText) ||
            part.partNumber.localizedCaseInsensitiveContains(searchText) ||
            part.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Category Methods
    
    func parts(for category: PartCategory) -> [InventoryPart] {
        parts.filter { $0.category == category }
    }
    
    func categoryCount(for category: PartCategory) -> Int {
        parts(for: category).count
    }
    
    // Map display names to categories
    func category(for displayName: String) -> PartCategory? {
        switch displayName {
        case "Engine Parts":
            return .engine
        case "Brake Components":
            return .brakes
        case "Electrical":
            return .electrical
        case "Tires & Wheels":
            return .tires
        case "Fluids & Oils":
            return .fluids
        default:
            return nil
        }
    }
    
    var allCategories: [PartCategory] {
        return PartCategory.predefinedCategories + customCategories
    }
    
    func displayName(for category: PartCategory) -> String {
        // For predefined categories, return custom display names
        if category.id == "engine" {
            return "Engine Parts"
        } else if category.id == "brakes" {
            return "Brake Components"
        } else if category.id == "tires" {
            return "Tires & Wheels"
        } else if category.id == "fluids" {
            return "Fluids & Oils"
        } else if category.id == "bodyWork" {
            return "Body Work"
        } else {
            // For others, just return the raw value
            return category.rawValue
        }
    }
    
    func icon(for category: PartCategory) -> String {
        // Return icon based on category ID
        switch category.id {
        case "engine":
            return "engine.combustion.fill"
        case "brakes":
            return "record.circle"
        case "electrical":
            return "bolt.fill"
        case "tires":
            return "circle.circle.fill"
        case "fluids":
            return "drop.fill"
        case "filters":
            return "air.purifier.fill"
        case "transmission":
            return "gearshape.2.fill"
        case "suspension":
            return "gauge.with.dots.needle.bottom.50percent"
        case "bodyWork":
            return "car.fill"
        case "other":
            return "wrench.and.screwdriver.fill"
        default:
            // Custom category default icon
            return "folder.fill"
        }
    }
    
    // Add custom category
    func addCustomCategory(_ name: String) {
        let newCategory = PartCategory.custom(name)
        if !customCategories.contains(where: { $0.id == newCategory.id }) {
            customCategories.append(newCategory)
        }
    }
    
    // MARK: - CRUD Operations
    
    func addPart(_ part: InventoryPart) {
        parts.append(part)
    }
    
    func updatePart(_ part: InventoryPart) {
        if let index = parts.firstIndex(where: { $0.id == part.id }) {
            parts[index] = part
        }
    }
    
    func deletePart(_ part: InventoryPart) {
        parts.removeAll { $0.id == part.id }
    }
    
    func deleteParts(at offsets: IndexSet, from categoryParts: [InventoryPart]) {
        for index in offsets {
            let partToDelete = categoryParts[index]
            deletePart(partToDelete)
        }
    }
}
