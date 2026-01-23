//
//  InAppVoiceSettings.swift
//  FleetTrack
//
//  Created by Antigravity on 23/01/26.
//

import Foundation
import SwiftUI
import Combine

class InAppVoiceSettings: ObservableObject {
    static let shared = InAppVoiceSettings()
    
    @Published var isVoiceEnabled: Bool {
        didSet { UserDefaults.standard.set(isVoiceEnabled, forKey: "isInAppVoiceEnabled") }
    }
    @Published var autoSpeak: Bool {
        didSet { UserDefaults.standard.set(autoSpeak, forKey: "autoSpeakOnScreenLoad") }
    }
    
    private init() {
        self.isVoiceEnabled = UserDefaults.standard.bool(forKey: "isInAppVoiceEnabled")
        // Default to true if not set
        if UserDefaults.standard.object(forKey: "autoSpeakOnScreenLoad") == nil {
            self.autoSpeak = true
        } else {
            self.autoSpeak = UserDefaults.standard.bool(forKey: "autoSpeakOnScreenLoad")
        }
    }
}
