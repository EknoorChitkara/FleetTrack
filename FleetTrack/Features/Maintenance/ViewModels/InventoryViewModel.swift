//
//  InventoryViewModel.swift
//  FleetTrack
//
//  Created for Inventory Management
//

import Combine
import Foundation
import SwiftUI

class InventoryViewModel: ObservableObject {
    @Published var parts: [InventoryPart] = []
    @Published var searchText: String = ""
    @Published var customCategories: [PartCategory] = []

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    init() {
        Task { await loadInventory() }
    }

    // MARK: - Data Loading

    @MainActor
    func loadInventory() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedParts = try await MaintenanceService.shared.fetchInventoryParts()
            self.parts = fetchedParts
            print("✅ Loaded \(fetchedParts.count) inventory parts from Supabase")
        } catch {
            self.errorMessage = "Failed to load inventory: \(error.localizedDescription)"
            print("❌ Error loading inventory: \(error)")
        }

        isLoading = false
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
            part.name.localizedCaseInsensitiveContains(searchText)
                || part.partNumber.localizedCaseInsensitiveContains(searchText)
                || part.category.rawValue.localizedCaseInsensitiveContains(searchText)
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

    @MainActor
    func addPart(_ part: InventoryPart) {
        Task {
            isLoading = true
            do {
                try await MaintenanceService.shared.addInventoryPart(part)
                await loadInventory()
            } catch {
                self.errorMessage = "Failed to add part: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    @MainActor
    func updatePart(_ part: InventoryPart) {
        Task {
            isLoading = true
            do {
                try await MaintenanceService.shared.updateInventoryPart(part)
                await loadInventory()
            } catch {
                self.errorMessage = "Failed to update part: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    @MainActor
    func deletePart(_ part: InventoryPart) {
        Task {
            isLoading = true
            do {
                try await MaintenanceService.shared.deleteInventoryPart(partId: part.id)
                parts.removeAll { $0.id == part.id }
            } catch {
                self.errorMessage = "Failed to delete part: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    @MainActor
    func deleteParts(at offsets: IndexSet, from categoryParts: [InventoryPart]) {
        for index in offsets {
            let partToDelete = categoryParts[index]
            deletePart(partToDelete)
        }
    }
}
