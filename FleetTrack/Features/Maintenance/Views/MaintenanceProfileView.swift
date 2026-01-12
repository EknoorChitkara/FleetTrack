//
//  ProfileView.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import SwiftUI

struct MaintenanceProfileView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()
            
            VStack {
                Text("Profile")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Profile settings coming soon")
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 8)
            }
        }
    }
}

#Preview {
    MaintenanceProfileView()
}
