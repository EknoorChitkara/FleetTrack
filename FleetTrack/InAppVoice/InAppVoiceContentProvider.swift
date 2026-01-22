//
//  InAppVoiceContentProvider.swift
//  FleetTrack
//
//  Created by Antigravity on 23/01/26.
//

import Foundation

/// Protocol for views that provide voice narration content
protocol InAppVoiceReadable {
    /// Returns a summarized string for voice narration
    func voiceSummary() -> String
}
