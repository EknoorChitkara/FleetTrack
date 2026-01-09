//
//  MaintenanceComponent.swift
//  FleetTrack
//
//  Created by FleetTrack Team on 2026-01-09.
//

import Foundation

enum MaintenanceComponent: String, Codable, CaseIterable, Identifiable {
    case engine = "Engine"
    case oil = "Oil"
    case oilChange = "Oil Change"
    case tires = "Tires"
    case tireReplacement = "Tire Replacement"
    case brakes = "Brakes"
    case brakeInspection = "Brake Inspection"
    case battery = "Battery"
    case transmission = "Transmission"
    case suspension = "Suspension"
    case electrical = "Electrical"
    case coolingSystem = "Cooling System"
    case other = "Other"
    
    var id: String { rawValue }
}
