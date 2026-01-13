//
//  MaintenancePriority.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import Foundation

enum MaintenancePriority: String, Codable, CaseIterable, Hashable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}
