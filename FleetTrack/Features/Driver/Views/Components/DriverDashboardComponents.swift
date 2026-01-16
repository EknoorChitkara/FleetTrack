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
                        let fuel = vehicle.fuelLevel ?? 0.0
                        HStack(spacing: 4) {
                            Image(systemName: "fuelpump.fill")
                                .font(.caption)
                            Text("\(Int(fuel))%")
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(fuel < 20 ? .red : .appEmerald)
                        
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
                Text(trip.endAddress ?? "Unknown Destination")
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
    let onTimeRate: Double
    let avgSpeed: Double
    let avgTripDist: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Performance Metrics")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                // 1. On-Time Delivery -> Emerald/Green
                AnimatedRingView(
                    title: "On-Time",
                    value: "\(Int(onTimeRate))%",
                    subValue: nil,
                    progress: onTimeRate / 100.0,
                    color: Color(hex: "#0b7333") // Bright Mint Green
                )
                
                Spacer()
                
                // 2. Avg Speed -> Replaces Safety Score -> Cyan/Blue
                AnimatedRingView(
                    title: "Avg. Speed",
                    value: String(format: "%.1f", avgSpeed),
                    subValue: "km/h",
                    progress: min(avgSpeed / 100.0, 1.0), // Normalizing assuming 100km/h is max for progress bar
                    color: Color(hex: "00B8D9") // Bright Cyan
                )
                
                Spacer()
                
                // 3. Avg Trip Dist -> Replaces Fuel Eff -> Orange/Amber
                AnimatedRingView(
                    title: "Avg. Trip",
                    value: "\(Int(avgTripDist))",
                    subValue: "km",
                    progress: min(avgTripDist / 500.0, 1.0), // Normalizing assuming 500km is 'full'
                    color: Color(hex: "FFAB00") // Amber/Orange
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

struct ScheduledTripCard: View {
    let trip: Trip
    let onStart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Scheduled")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .clipShape(Capsule())
                
                Spacer()
                
                if let distance = trip.formattedDistance {
                    HStack(spacing: 4) {
                        Image(systemName: "road.lanes")
                        Text(distance)
                    }
                    .font(.caption)
                    .foregroundColor(.appSecondaryText)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.appSecondaryText)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onStart()
            }
            
            // Route
            HStack(spacing: 12) {
                // Connector
                VStack(spacing: 0) {
                    Circle()
                        .fill(Color.appEmerald)
                        .frame(width: 12, height: 12)
                    
                    Rectangle()
                        .fill(Color.appSecondaryText.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 4)
                    
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                }
                .padding(.vertical, 4)
                
                // Content
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PICKUP")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.appSecondaryText)
                            .tracking(1)
                        Text(trip.startAddress ?? "Unknown Location")
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DROPOFF")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.appSecondaryText)
                            .tracking(1)
                        Text(trip.endAddress ?? "Unknown Location")
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "car.side.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.trailing, 8)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Footer & Action
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let purpose = trip.purpose {
                        HStack {
                            Image(systemName: "doc.text")
                            Text(purpose)
                        }
                        .font(.caption)
                        .foregroundColor(.appSecondaryText)
                    }
                    
                    if let date = trip.startTime {
                        HStack {
                            Image(systemName: "calendar")
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                        }
                        .font(.caption)
                        .foregroundColor(.appEmerald)
                    }
                }
                
                Spacer()
                
                Button(action: onStart) {
                    HStack {
                        Text("Start Trip")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.appEmerald)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.appCardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.appEmerald.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ActiveTripCard: View {
    let trip: Trip
    let onResume: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Ongoing")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .clipShape(Capsule())
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .opacity(0.8)
                    Text("Live Tracking")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onResume()
            }
            
            // Destination Focus
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: "flag.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("DROPOFF")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.appSecondaryText)
                        .tracking(1)
                    Text(trip.endAddress ?? "Unknown Location")
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "car.side.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.trailing, 8)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            // Action
            Button(action: onResume) {
                HStack {
                    Text("End Trip") // Leads to map where End Trip is available
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.appCardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
        )
    }
}


