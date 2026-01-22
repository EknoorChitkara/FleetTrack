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
        VStack(spacing: 20) {
            // 1. Odometer Readings
            VStack(alignment: .leading, spacing: 12) {
                Text("Odometer Readings")
                    .font(.headline)
                    .padding(.horizontal)
                
                HStack(spacing: 16) {
                    InfoCard(
                        title: "START ODO",
                        value: "\(Int(trip.startOdometer ?? 0))",
                        unit: "km",
                        color: .blue
                    )
                    
                    InfoCard(
                        title: "END ODO",
                        value: "\(Int(trip.endOdometer ?? 0))",
                        unit: "km",
                        color: .blue
                    )
                    
                    InfoCard(
                        title: "DIFFERENCE",
                        value: "\(Int((trip.endOdometer ?? 0) - (trip.startOdometer ?? 0)))",
                        unit: "km",
                        color: .green
                    )
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // 2. Fuel Levels
            VStack(alignment: .leading, spacing: 12) {
                Text("Fuel Levels")
                    .font(.headline)
                    .padding(.horizontal)
                
                HStack(spacing: 16) {
                    InfoCard(
                        title: "START FUEL",
                        value: "\(Int(trip.startFuelLevel ?? 0))",
                        unit: "%",
                        color: .orange
                    )
                    
                    InfoCard(
                        title: "END FUEL",
                        value: "\(Int(trip.endFuelLevel ?? 0))",
                        unit: "%",
                        color: .orange
                    )
                    
                    InfoCard(
                        title: "CONSUMED",
                        value: String(format: "%.1f", calculatedConsumption),
                        unit: "L",
                        color: .red
                    )
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // 3. Trip Timing
            VStack(alignment: .leading, spacing: 12) {
                Text("Trip Timing")
                    .font(.headline)
                    .padding(.horizontal)
                
                HStack(spacing: 16) {
                    TimeCard(
                        title: "STARTED",
                        value: trip.startTime?.formatted(date: .omitted, time: .shortened) ?? "N/A"
                    )
                    
                    TimeCard(
                        title: "COMPLETED",
                        value: trip.endTime?.formatted(date: .omitted, time: .shortened) ?? "N/A"
                    )
                    
                    TimeCard(
                        title: "DURATION",
                        value: formattedDuration
                    )
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // 4. Efficiency Card
            HStack(spacing: 16) {
                EfficiencyCard(
                    title: "Trip Efficiency",
                    value: String(format: "%.1f km/L", calculatedEfficiency),
                    subtitle: "Target: \(String(format: "%.1f", vehicle?.standardFuelEfficiency ?? 0))",
                    color: efficiencyColor
                )
            }
            .padding(.horizontal)
            
            Divider()
            
            // 5. Photos Grid
            VStack(alignment: .leading) {
                Text("Trip Photos")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        PhotoEvidenceView(title: "Start Odo", url: trip.startOdometerPhotoUrl)
                        PhotoEvidenceView(title: "Start Fuel", url: trip.startFuelGaugePhotoUrl)
                        PhotoEvidenceView(title: "End Odo", url: trip.endOdometerPhotoUrl)
                        PhotoEvidenceView(title: "End Fuel", url: trip.endFuelGaugePhotoUrl)
                    }
                    .padding(.horizontal)
                }
            }
            
            Divider()
            
            // 6. Refill History
            VStack(alignment: .leading) {
                Text("Refill History (\(refills.count))")
                    .font(.headline)
                    .padding(.horizontal)
                
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.appSecondaryText)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.appSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PhotoEvidenceView: View {
    let title: String
    let url: String?
    
    var body: some View {
        VStack {
            if let urlString = url, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "photo.slash").foregroundColor(.gray))
            }
            
            Text(title)
                .font(.caption2)
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
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.appSecondaryText)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.appSecondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Time Card
struct TimeCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.appSecondaryText)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
