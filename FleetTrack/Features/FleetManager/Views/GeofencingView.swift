//
//  GeofencingView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct GeofencingView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Icon
                    Image(systemName: "map.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.purple)
                        .padding(30)
                        .background(Color.purple.opacity(0.1))
                        .clipShape(Circle())
                    
                    // Title
                    Text("Geofencing")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Message
                    VStack(spacing: 12) {
                        Text("Coming Soon!")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.appEmerald)
                        
                        Text("Stay tuned for virtual boundary management")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Text("Track vehicles in real-time and get alerts when they enter or exit designated zones")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    // Close Button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Got It")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appEmerald)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarItems(
                trailing: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            )
        }
    }
}
