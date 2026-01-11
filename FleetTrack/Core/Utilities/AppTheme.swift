//
//  AppTheme.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import SwiftUI

/// Centralized color theme system following strict dark UI design guidelines
struct AppTheme {
    
    // MARK: - Base Neutrals (Foundation)
    
    /// Primary app background: pure black for true dark mode
    static let backgroundPrimary = Color(hex: "#000000")
    
    /// Secondary surfaces (cards, sheets, modals): #1A1A1C to #1E1E20
    static let backgroundSecondary = Color(hex: "#1A1A1C")
    
    /// Elevated or highlighted surfaces (1-3% lighter than secondary)
    static let backgroundElevated = Color(hex: "#1E1E20")
    
    // MARK: - Text Color Hierarchy
    
    /// Primary text (titles, IDs, key labels): #FFFFFF
    static let textPrimary = Color(hex: "#FFFFFF")
    
    /// Secondary text (descriptions, labels): #B0B0B3
    static let textSecondary = Color(hex: "#B0B0B3")
    
    /// Tertiary text (metadata, timestamps, hints): #7D7D80
    static let textTertiary = Color(hex: "#7D7D80")
    
    /// Disabled text: #555558
    static let textDisabled = Color(hex: "#555558")
    
    // MARK: - Primary Accent Color (Neon Green)
    
    /// Base neon green accent: #00E676
    /// Reserved strictly for: Active states, Selected items, Primary CTAs, Active/running statuses
    static let accentPrimary = Color(hex: "#00E676")
    
    /// Hover / emphasis neon green: #1AFF7C
    static let accentHover = Color(hex: "#1AFF7C")
    
    // MARK: - Status Color System
    
    /// Active / Success text color
    static let statusActiveText = Color(hex: "#00E676")
    
    /// Active / Success background (dark green-tinted charcoal, low saturation)
    static let statusActiveBackground = Color(hex: "#0A1F14")
    
    /// Maintenance / Warning amber/orange: #FFB020 (muted, not bright)
    static let statusWarning = Color(hex: "#FFB020")
    
    /// Warning background (subtle)
    static let statusWarningBackground = Color(hex: "#1F1A0A")
    
    /// Idle / Inactive neutral gray: #6B6B6E
    static let statusIdle = Color(hex: "#6B6B6E")
    
    /// Idle background (subtle)
    static let statusIdleBackground = Color(hex: "#16161A")
    
    /// Error / Critical muted red: #D64545
    static let statusError = Color(hex: "#D64545")
    
    /// Error background (subtle)
    static let statusErrorBackground = Color(hex: "#1F0A0A")
    
    // MARK: - Dividers & Borders
    
    /// Primary divider/border color: #262629
    static let dividerPrimary = Color(hex: "#262629")
    
    /// Secondary divider/border color: #2A2A2D
    static let dividerSecondary = Color(hex: "#2A2A2D")
    
    // MARK: - Icon Colors
    
    /// Default icons: #B0B0B3
    static let iconDefault = Color(hex: "#B0B0B3")
    
    /// Active icons: Neon green
    static let iconActive = Color(hex: "#00E676")
    
    /// Disabled icons: #555558
    static let iconDisabled = Color(hex: "#555558")
    
    // MARK: - Spacing & Layout
    
    static let spacing = Spacing()
    
    struct Spacing {
        let xs: CGFloat = 4
        let sm: CGFloat = 8
        let md: CGFloat = 16
        let lg: CGFloat = 24
        let xl: CGFloat = 32
        let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    static let cornerRadius = CornerRadius()
    
    struct CornerRadius {
        let small: CGFloat = 8
        let medium: CGFloat = 12
        let large: CGFloat = 16
        let extraLarge: CGFloat = 24
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
