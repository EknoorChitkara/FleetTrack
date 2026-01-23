//
//  InAppVoiceCoordinator.swift
//  FleetTrack
//
//  Created by Antigravity on 23/01/26.
//

import Foundation
import SwiftUI
import Combine

/// Coordinator to help with speech context, although mostly decentralized to views.
class InAppVoiceCoordinator: ObservableObject {
    static let shared = InAppVoiceCoordinator()
    
    // Can be used to register the 'active' screen if needed, 
    // but the SwiftUI 'onAppear' approach is more idiomatic.
    // We'll keep this as a placeholder for extension (e.g., global alerts).
}
