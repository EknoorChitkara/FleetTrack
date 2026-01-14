//
//  DriverDashboardComponents.swift
//  FleetTrack
//

import SwiftUI

struct DriverStatCard: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.appSecondaryText)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.appEmerald)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.headline)
                        .foregroundColor(.appEmerald)
                        .padding(.bottom, 4)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let progress: Double // 0 to 1
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(Color.appEmerald)
                        .frame(width: geo.size.width * CGFloat(progress), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

struct AssignedVehicleCard: View {
    let vehicle: Vehicle?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Assigned Vehicle")
                .font(.headline)
                .foregroundColor(.white)
            
            if let vehicle = vehicle {
                HStack(spacing: 16) {
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.appEmerald)
                        .frame(width: 60, height: 60)
                        .background(Color.appEmerald.opacity(0.1))
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(vehicle.manufacturer) \(vehicle.model)")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(vehicle.registrationNumber)
                            .font(.subheadline)
                            .foregroundColor(.appSecondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "fuelpump.fill")
                                .font(.caption)
                            Text("\(Int(vehicle.fuelLevel))%")
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(vehicle.fuelLevel < 20 ? .red : .appEmerald)
                        
                        Text(vehicle.status.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.appEmerald.opacity(0.2))
                            .foregroundColor(.appEmerald)
                            .cornerRadius(4)
                    }
                }
            } else {
                Text("No vehicle assigned")
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct RecentTripRow: View {
    let trip: Trip
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.appEmerald.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundColor(.appEmerald)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.endLocation?.address ?? "Unknown Destination")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(trip.startTime?.formatted(date: .abbreviated, time: .shortened) ?? "No date")
                    .font(.caption2)
                    .foregroundColor(.appSecondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(trip.formattedDistance ?? "0 km")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(trip.status?.rawValue ?? "Unknown")
                    .font(.caption2)
                    .foregroundColor(trip.status == .completed ? .appEmerald : .orange)
            }
        }
        .padding(.vertical, 8)
    }
}

struct DriverCustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            DriverTabBarItem(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            Spacer()
            
            DriverTabBarItem(icon: "map.fill", title: "Trips", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            Spacer()
            
            DriverTabBarItem(icon: "bell.fill", title: "Alerts", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        .background(Color.appCardBackground.opacity(0.95))
        .clipShape(Capsule())
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
    }
}

struct DriverTabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .appEmerald : .appSecondaryText)
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(isSelected ? Color.appEmerald.opacity(0.1) : Color.clear)
            .clipShape(Capsule())
        }
    }
}

struct AnimatedRingView: View {
    let title: String
    let value: String
    let subValue: String?
    let progress: Double
    let color: Color
    
    @State private var animatedProgress: Double = 0.0
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                // Progress Circle
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 80, height: 80)
                
                // Value Text
                VStack(spacing: 2) {
                    Text(value)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if let sub = subValue {
                        Text(sub)
                            .font(.system(size: 10))
                            .foregroundColor(.appSecondaryText)
                    }
                }
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.appSecondaryText)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                animatedProgress = progress
            }
        }
    }
}

struct PerformanceMetricsChart: View {
    let driver: Driver?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Performance Metrics")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                // 1. On-Time Delivery
                AnimatedRingView(
                    title: "On-Time",
                    value: "\(Int(driver?.onTimeDeliveryRate ?? 0))%",
                    subValue: nil,
                    progress: (driver?.onTimeDeliveryRate ?? 0) / 100.0,
                    color: .appEmerald
                )
                
                Spacer()
                
                // 2. Safety Score
                AnimatedRingView(
                    title: "Safety Score",
                    value: driver?.formattedRating ?? "0.0",
                    subValue: "/ 5.0",
                    progress: (driver?.rating ?? 0) / 5.0,
                    color: .purple // Distinct color
                )
                
                Spacer()
                
                // 3. Fuel Efficiency
                AnimatedRingView(
                    title: "Fuel Eff.",
                    value: String(format: "%.1f", driver?.fuelEfficiency ?? 0.0),
                    subValue: "L/100km",
                    progress: (driver?.fuelEfficiency ?? 0.0) > 0 ? 0.7 : 0.0, // Arbitrary progress for fuel as it's not a 0-100 metric
                    color: .blue // Distinct color
                )
            }
            .padding(.horizontal, 8)
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
