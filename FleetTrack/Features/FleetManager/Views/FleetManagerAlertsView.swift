//
//  FleetManagerAlertsView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct FleetManagerAlertsView: View {
    @State private var selectedSegment = 0
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack(spacing: 8) {
                    Text("Alerts")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("0")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.red)
                        .clipShape(Circle())
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20) // Reduced top padding
                
                // Segment Control
                HStack(spacing: 12) {
                    AlertSegmentButton(title: "All (0)", isSelected: selectedSegment == 0) {
                        selectedSegment = 0
                    }
                    
                    AlertSegmentButton(title: "Unread (0)", isSelected: selectedSegment == 1) {
                        selectedSegment = 1
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Empty State
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No alerts to display")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
    }
}

struct AlertSegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.appEmerald : Color(white: 0.2))
                .foregroundColor(isSelected ? .black : .white)
                .cornerRadius(8)
        }
    }
}
