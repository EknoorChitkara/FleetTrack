//
//  GeofenceView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct GeofenceView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Text("Geofence")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding()
                
                // Placeholder Content
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "map.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.appEmerald)
                    
                    Text("Geofence Management")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Coming Soon")
                        .font(.system(size: 14))
                        .foregroundColor(.appSecondaryText)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}
