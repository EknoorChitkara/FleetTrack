//
//  ProfileView.swift
//  FleetTrack
//
//  Created by FleetTrack Team on 2026-01-09.
//

import SwiftUI

struct ProfileView: View {
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
    ProfileView()
}
