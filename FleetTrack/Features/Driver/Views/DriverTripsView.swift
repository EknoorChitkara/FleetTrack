//
//  DriverTripsView.swift
//  FleetTrack
//

import SwiftUI

struct DriverTripsView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Text("Trips")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.appEmerald.opacity(0.8))
                        .shadow(color: .appEmerald.opacity(0.3), radius: 20)
                    
                    VStack(spacing: 8) {
                        Text("My Trips")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Coming Soon")
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
    DriverTripsView()
}
