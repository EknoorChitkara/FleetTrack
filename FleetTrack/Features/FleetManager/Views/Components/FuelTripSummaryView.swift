//
//  FuelTripSummaryView.swift
//  FleetTrack
//
//  Created for Fleet Managers to view fuel analytics for a trip
//

import SwiftUI

struct FuelTripSummaryView: View {
    let trip: Trip
    let vehicle: Vehicle?
    @State private var refills: [FuelRefill] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 24) {
            // 1. Odometer Readings
            VStack(alignment: .leading, spacing: 14) {
                Text("Odometer Readings")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                HStack(spacing: 12) {
                    InfoCard(
                        title: "START ODO",
                        value: trip.startOdometer != nil ? "\(Int(trip.startOdometer!))" : "—",
                        unit: trip.startOdometer != nil ? "km" : "",
                        color: .blue
                    )
                    
                    InfoCard(
                        title: "END ODO",
                        value: trip.endOdometer != nil ? "\(Int(trip.endOdometer!))" : "In Progress",
                        unit: trip.endOdometer != nil ? "km" : "",
                        color: trip.endOdometer != nil ? .blue : .orange
                    )
                    
                    InfoCard(
                        title: "DIFFERENCE",
                        value: (trip.endOdometer != nil && trip.startOdometer != nil) ? "\(Int(trip.endOdometer! - trip.startOdometer!))" : "—",
                        unit: (trip.endOdometer != nil && trip.startOdometer != nil) ? "km" : "",
                        color: .green
                    )
                }
                .padding(.horizontal, 12)
            }
            
            Divider()
                .padding(.horizontal, 20)
            
            // 2. Fuel Levels
            VStack(alignment: .leading, spacing: 14) {
                Text("Fuel Levels")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                HStack(spacing: 12) {
                    InfoCard(
                        title: "START FUEL",
                        value: trip.startFuelLevel != nil ? "\(Int(trip.startFuelLevel!))" : "—",
                        unit: trip.startFuelLevel != nil ? "%" : "",
                        color: .orange
                    )
                    
                    InfoCard(
                        title: "END FUEL",
                        value: trip.endFuelLevel != nil ? "\(Int(trip.endFuelLevel!))" : "In Progress",
                        unit: trip.endFuelLevel != nil ? "%" : "",
                        color: trip.endFuelLevel != nil ? .orange : .blue
                    )
                    
                    InfoCard(
                        title: "CONSUMED",
                        value: (trip.endFuelLevel != nil && trip.startFuelLevel != nil) ? String(format: "%.1f", calculatedConsumption) : "—",
                        unit: (trip.endFuelLevel != nil && trip.startFuelLevel != nil) ? "L" : "",
                        color: trip.endFuelLevel != nil ? .red : .gray
                    )
                }
                .padding(.horizontal, 12)
            }
            
            Divider()
                .padding(.horizontal, 20)
            
            // 3. Trip Timing
            VStack(alignment: .leading, spacing: 14) {
                Text("Trip Timing")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                HStack(spacing: 12) {
                    TimeCard(
                        title: "STARTED",
                        value: trip.startTime?.formatted(date: .omitted, time: .shortened) ?? "N/A"
                    )
                    
                    TimeCard(
                        title: trip.endTime != nil ? "COMPLETED" : "STATUS",
                        value: trip.endTime?.formatted(date: .omitted, time: .shortened) ?? "Ongoing"
                    )
                    
                    TimeCard(
                        title: "DURATION",
                        value: trip.endTime != nil ? formattedDuration : "In Progress"
                    )
                }
                .padding(.horizontal, 12)
            }
            
            Divider()
                .padding(.horizontal, 20)
            
            // 4. Efficiency Card
            if trip.endOdometer != nil && trip.endFuelLevel != nil {
                HStack(spacing: 16) {
                    EfficiencyCard(
                        title: "Trip Efficiency",
                        value: String(format: "%.1f km/L", calculatedEfficiency),
                        subtitle: "Target: \(String(format: "%.1f", vehicle?.standardFuelEfficiency ?? 0))",
                        color: efficiencyColor
                    )
                }
                .padding(.horizontal, 12)
            } else {
                HStack(spacing: 16) {
                    EfficiencyCard(
                        title: "Trip Efficiency",
                        value: "Pending",
                        subtitle: "Available after trip completion",
                        color: .gray
                    )
                }
                .padding(.horizontal, 12)
            }
            
            Divider()
                .padding(.horizontal, 20)
            
            // 5. Photos Grid
            VStack(alignment: .leading, spacing: 14) {
                Text("Trip Photos")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        PhotoEvidenceView(title: "Start Odo", url: trip.startOdometerPhotoUrl)
                        PhotoEvidenceView(title: "Start Fuel", url: trip.startFuelGaugePhotoUrl)
                        
                        if trip.status == .completed {
                            PhotoEvidenceView(title: "End Odo", url: trip.endOdometerPhotoUrl)
                            PhotoEvidenceView(title: "End Fuel", url: trip.endFuelGaugePhotoUrl)
                        } else {
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appCardBackground)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "clock.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.orange)
                                            Text("Pending")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.appSecondaryText)
                                        }
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                                Text("End Odo")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appCardBackground)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "clock.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.orange)
                                            Text("Pending")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.appSecondaryText)
                                        }
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                                Text("End Fuel")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            Divider()
                .padding(.horizontal, 20)
            
            // 6. Refill History
            VStack(alignment: .leading, spacing: 14) {
                Text("Refill History (\(refills.count))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                if refills.isEmpty {
                    Text("No refills logged during this trip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    ForEach(refills) { refill in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(String(format: "%.1f", refill.fuelAddedLiters))L Added")
                                    .fontWeight(.medium)
                                Text(refill.timestamp.formatted())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if let cost = refill.fuelCost {
                                Text("$\(String(format: "%.2f", cost))")
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical)
        .task {
            // Load refills
            do {
                refills = try await FuelTrackingService.shared.fetchTripRefills(tripId: trip.id)
            } catch {
                print("Failed to load refills: \(error)")
            }
            isLoading = false
        }
    }
    
    // MARK: - Computed Props
    
    var calculatedConsumption: Double {
        FuelCalculationService.shared.calculateSensorBasedConsumption(
            startPercentage: trip.startFuelLevel ?? 0,
            endPercentage: trip.endFuelLevel ?? 0,
            tankCapacity: vehicle?.tankCapacity ?? 60.0,
            refills: refills
        )
    }
    
    var calculatedEfficiency: Double {
        FuelCalculationService.shared.calculateTripEfficiency(
            distanceKm: trip.distance ?? 0,
            consumedLiters: calculatedConsumption
        )
    }
    
    var efficiencyColor: Color {
        guard let std = vehicle?.standardFuelEfficiency, std > 0 else { return .gray }
        if calculatedEfficiency >= std { return .green }
        if calculatedEfficiency >= std * 0.9 { return .yellow }
        return .red
    }
    
    var formattedDuration: String {
        guard let start = trip.startTime, let end = trip.endTime else {
            return "N/A"
        }
        let duration = end.timeIntervalSince(start)
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Subviews

struct EfficiencyCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.appSecondaryText)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.appSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1.5)
        )
    }
}

struct PhotoEvidenceView: View {
    let title: String
    let url: String?
    @State private var showFullScreen = false
    
    var body: some View {
        VStack(spacing: 8) {
            if let urlString = url, !urlString.isEmpty, let photoURL = URL(string: urlString) {
                Button(action: {
                    showFullScreen = true
                }) {
                    AsyncImage(url: photoURL) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                Color.appCardBackground
                                ProgressView()
                                    .tint(.appEmeraldLight)
                            }
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            ZStack {
                                Color.red.opacity(0.1)
                                VStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 16))
                                        .foregroundColor(.red)
                                    Text("Failed")
                                        .font(.system(size: 9))
                                        .foregroundColor(.red)
                                }
                            }
                        @unknown default:
                            Color.gray.opacity(0.3)
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appEmeraldLight.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showFullScreen) {
                    FullScreenPhotoView(imageURL: photoURL, title: title)
                }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCardBackground)
                    .frame(width: 100, height: 100)
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "photo.slash")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                            Text("No Photo")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }
}

// MARK: - Full Screen Photo View
struct FullScreenPhotoView: View {
    let imageURL: URL
    let title: String
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastScale * value
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                        if scale < 1 {
                                            withAnimation {
                                                scale = 1
                                                lastScale = 1
                                            }
                                        } else if scale > 4 {
                                            withAnimation {
                                                scale = 4
                                                lastScale = 4
                                            }
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation {
                                    if scale > 1 {
                                        scale = 1
                                        lastScale = 1
                                    } else {
                                        scale = 2
                                        lastScale = 2
                                    }
                                }
                            }
                    case .failure:
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.red)
                            Text("Failed to load image")
                                .foregroundColor(.white)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Info Card for Odometer and Fuel
struct InfoCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.appSecondaryText)
                .textCase(.uppercase)
                .tracking(0.5)
                .lineLimit(1)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.85)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appSecondaryText)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - Time Card
struct TimeCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.appSecondaryText)
                .textCase(.uppercase)
                .tracking(0.5)
                .lineLimit(1)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}
