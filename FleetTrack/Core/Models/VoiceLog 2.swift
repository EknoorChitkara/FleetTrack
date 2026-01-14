//
//  VoiceLog.swift
//  FleetTrack
//
//  Created for Driver
//

import Foundation

struct VoiceLog: Identifiable, Codable, Hashable {
    let id: UUID
    var tripId: UUID
    var audioURL: URL? // Local or remote URL
    var duration: TimeInterval
    var createdAt: Date
    
    init(id: UUID = UUID(), tripId: UUID, audioURL: URL? = nil, duration: TimeInterval, createdAt: Date = Date()) {
        self.id = id
        self.tripId = tripId
        self.audioURL = audioURL
        self.duration = duration
        self.createdAt = createdAt
    }
}
