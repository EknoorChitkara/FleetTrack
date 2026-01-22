//
//  InAppVoiceManager.swift
//  FleetTrack
//
//  Created by Antigravity on 23/01/26.
//

import Foundation
import AVFoundation
import UIKit
import Combine

class InAppVoiceManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = InAppVoiceManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    private let settings = InAppVoiceSettings.shared
    
    @Published var isSpeaking: Bool = false
    
    // We keep track of the last spoken content for replay functionality
    private var lastSpokenContent: String?
    
    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            // Use playback category, mixWithOthers to not hard-mute other apps, 
            // duckOthers could be used if we want to lower background music.
            // For now, mixWithOthers + duckOthers seems appropriate for voiceover.
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session for InAppVoice: \(error)")
        }
    }
    
    func speak(_ text: String, force: Bool = false) {
        guard settings.isVoiceEnabled || force else { return }
        guard !text.isEmpty else { return }
        
        // Interaction Rule: Stop previous narration when screen changes (or new content arrives)
        stop()
        
        // System VoiceOver Check
        if UIAccessibility.isVoiceOverRunning {
            // Requirement: "Reduce verbosity OR auto-disable". 
            // We'll auto-disable/silence to prevent double speak as per Safe usage.
            // But if the user TAPPED the toggle button explicitly, they might want it.
            // For now, if system VO is on, we skip automatic speaking unless forced.
            if !force {
                print("System VoiceOver is running. In-App Voice suppressed.")
                return 
            }
        }
        
        lastSpokenContent = text
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        
        // Ensure audio session is active
        try? AVAudioSession.sharedInstance().setActive(true)
        
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
    
    func replayLast() {
        if let content = lastSpokenContent {
            speak(content, force: true) // Force replay even if VO is on, as user explicitly requested it
        }
    }
    
    func toggleVoiceMode() {
        settings.isVoiceEnabled.toggle()
        if !settings.isVoiceEnabled {
            stop()
        } else {
            // Optionally speak a confirmation or the current screen if available
            speak("Voice mode enabled.")
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
