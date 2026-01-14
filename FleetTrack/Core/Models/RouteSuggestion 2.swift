//
//  RouteSuggestion.swift
//  FleetTrack
//
//  Created for Driver
//

import Foundation

enum RouteTag: String, Codable {
    case standard = "Standard"
    case low = "Low"
    case optimal = "Optimal"
}

struct RouteSuggestion: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String // Fastest, Fuel Saver, Balanced
    var duration: TimeInterval // seconds
    var distance: Double // km
    var tag: RouteTag?
    var isRecommended: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        duration: TimeInterval,
        distance: Double,
        tag: RouteTag? = nil,
        isRecommended: Bool = false
    ) {
        self.id = id
        self.name = name
        self.duration = duration
        self.distance = distance
        self.tag = tag
        self.isRecommended = isRecommended
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}
