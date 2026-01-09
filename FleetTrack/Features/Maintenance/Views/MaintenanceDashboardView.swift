//
//  MaintenanceDashboardView.swift
//  FleetTrack
//
//  Created by FleetTrack on 08/01/26.
//

import SwiftUI

struct MaintenanceDashboardView: View {
    let user: User
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.appEmerald)
                    .shadow(color: .appEmerald.opacity(0.3), radius: 10)
                
                Text("Maintenance Portal")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.appEmerald)
                        Text("Name: \(user.name)")
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Image(systemName: "briefcase.fill")
                            .foregroundColor(.appEmerald)
                        Text("Role: \(user.role.rawValue)")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appCardBackground)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appEmerald.opacity(0.2), lineWidth: 1))
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
