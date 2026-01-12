//
//  FleetManagerComponents.swift
//  FleetTrack
//

import SwiftUI

struct TripRow: View {
    let trip: FMTrip
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.purple.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "map.fill").foregroundColor(.purple))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(trip.startLocation) → \(trip.destination)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(trip.vehicleName)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(trip.distance)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.appEmerald)
                Text(trip.startDate, style: .date)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let activity: FMActivity
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: activity.icon).foregroundColor(.blue))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(activity.description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(activity.timestamp, style: .time)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
    }
}
