//
//  AppFonts.swift
//  FleetTrack
//
//  Created for Accessibility Enhancements
//

import SwiftUI

extension Font {
    /// Large Header (scaled)
    static var appTitle: Font {
        .system(.title, design: .rounded, weight: .bold)
    }
    
    /// Normal Header (scaled)
    static var appHeadline: Font {
        .system(.headline, design: .rounded, weight: .semibold)
    }
    
    /// Subheadline (scaled)
    static var appSubheadline: Font {
        .system(.subheadline, design: .rounded, weight: .medium)
    }
    
    /// Body text (scaled)
    static var appBody: Font {
        .system(.body, design: .default, weight: .regular)
    }
    
    /// Caption (scaled)
    static var appCaption: Font {
        .system(.caption, design: .default, weight: .regular)
    }
    
    /// Stats value (scaled large)
    static var appStatValue: Font {
        .system(.title2, design: .rounded, weight: .bold)
    }
}
