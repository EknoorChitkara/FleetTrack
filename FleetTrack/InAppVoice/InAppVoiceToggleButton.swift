//
//  InAppVoiceToggleButton.swift
//  FleetTrack
//
//  Created by Antigravity on 23/01/26.
//

import SwiftUI

struct InAppVoiceToggleButton: View {
    @ObservedObject private var settings = InAppVoiceSettings.shared
    @ObservedObject private var manager = InAppVoiceManager.shared
    
    // Draggable State
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Button(action: {
                    if settings.isVoiceEnabled {
                         manager.replayLast()
                    } else {
                         toggleVoiceMode()
                    }
                }) {
                    ZStack {
                        // Blended Background (Darker/Transparent)
                        Circle()
                            .fill(Color.black.opacity(0.6)) // Darker background to blend
                            .frame(width: 48, height: 48) // Slightly smaller
                            .overlay(
                                Circle()
                                    .stroke(settings.isVoiceEnabled ? Color.appEmerald : Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        // Active Indicator Ring (when ON)
                        if settings.isVoiceEnabled {
                            Circle()
                                .stroke(Color.appEmerald.opacity(0.6), lineWidth: 2)
                                .frame(width: 46, height: 46)
                        }
                        
                        Image(systemName: settings.isVoiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .foregroundColor(settings.isVoiceEnabled ? .appEmerald : .gray) // Use app theme green
                            .font(.system(size: 20, weight: .semibold))
                            // Bounce when toggled, Pulse when speaking
                            .symbolEffect(.bounce, value: settings.isVoiceEnabled)
                            .symbolEffect(.pulse.byLayer, options: .repeating, isActive: manager.isSpeaking)
                    }
                }
                .accessibilityLabel("Voice Narration")
                .accessibilityHint(settings.isVoiceEnabled ? "Double tap to Replay. Long press for options. Drag to move." : "Double tap to turn ON. Drag to move.")
                .accessibilityAddTraits(.isButton)
                // Context Menu to fully disable if "irritating"
                .contextMenu {
                    Button(role: .destructive) {
                        settings.isVoiceEnabled = false
                        // Ideally we'd have a 'hide' pref, but turning off is the first step
                        manager.stop()
                    } label: {
                        Label("Turn Off Voice", systemImage: "power")
                    }
                }
            }
            .position(x: geometry.size.width - 40, y: 100) // Initial position (top-rightish)
            .offset(x: offset.width, y: offset.height)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        self.offset = CGSize(
                            width: self.lastOffset.width + gesture.translation.width,
                            height: self.lastOffset.height + gesture.translation.height
                        )
                    }
                    .onEnded { _ in
                        self.lastOffset = self.offset
                    }
            )
        }
        // Ensure it doesn't block hits globally, but the button itself captures hits
        .allowsHitTesting(true) 
    }
    
    private func toggleVoiceMode() {
        manager.toggleVoiceMode()
    }
}

