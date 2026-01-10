//
//  DriverAlertsView.swift
//  FleetTrack
//

import SwiftUI

struct DriverAlertsView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.6))
                    
                    VStack(spacing: 8) {
                        Text("Alerts")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("No new alerts")
                            .font(.headline)
                            .foregroundColor(.appSecondaryText)
                    }
                }
                
                Spacer()
                Spacer() // Extra spacer to balance the bottom bar
            }
        }
    }
}

#Preview {
    DriverAlertsView()
}
