//
//  AlertsView.swift
//  FleetTrack
//
//  Created by FleetTrack Team on 2026-01-09.
//

import SwiftUI

struct AlertsView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()
            
            VStack {
                Text("Alerts")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("System alerts and notifications")
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 8)
            }
        }
    }
}

#Preview {
    AlertsView()
}
