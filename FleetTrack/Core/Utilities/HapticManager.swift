//
//  HapticManager.swift
//  FleetTrack
//
//  Created for Accessibility Enhancements
//

import UIKit

/// Centralized manager for haptic feedback across the application
class HapticManager {
    static let shared = HapticManager()
    
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    private init() {
        notificationGenerator.prepare()
        impactGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    /// Trigger a success haptic (e.g., trip completed, task saved)
    func triggerSuccess() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Trigger a warning haptic (e.g., low fuel, part below threshold)
    func triggerWarning() {
        notificationGenerator.notificationOccurred(.warning)
    }
    
    /// Trigger an error haptic (e.g., login failed, service error)
    func triggerError() {
        notificationGenerator.notificationOccurred(.error)
    }
    
    /// Trigger a standard impact haptic (e.g., starting a trip, button press)
    func triggerImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Trigger a selection change haptic (e.g., picker scroll, tab change)
    func triggerSelection() {
        selectionGenerator.selectionChanged()
    }
}
