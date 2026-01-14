//
//  DriverAboutView.swift
//  FleetTrack
//
//  Created for Driver
//

import SwiftUI

struct DriverAboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .padding(10)
                            .background(Color(white: 0.2))
                            .clipShape(Circle())
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("About")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                .padding(.top)
                
                Spacer()
                
                // App Info
                VStack(spacing: 20) {
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.appEmerald)
                    
                    Text("Fleet Dashboard")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Version 1.0.0")
                        .foregroundColor(.gray)
                    
                    Text("© 2026 Fleet Dashboard Inc.\nAll rights reserved.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                }
                
                Spacer()
                Spacer() 
            }
        }
        .navigationBarHidden(true)
    }
}
