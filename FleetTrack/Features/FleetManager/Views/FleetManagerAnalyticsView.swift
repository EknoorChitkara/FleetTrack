//
//  FleetManagerAnalyticsView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI
import Charts

struct FleetManagerAnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analytics")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Fleet performance insights")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // KPI Cards
                kpiGrid
                    .padding(.horizontal)
                
                // Main Charts
                costTrendChart
                    .padding(.horizontal)
                
                distanceTrendChart
                    .padding(.horizontal)
                
                vehicleCostDistributionChart
                    .padding(.horizontal)
                
                Spacer(minLength: 120)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
    
    // MARK: - KPI Grid
    
    private var kpiGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            
            // Total Cost
            VStack(alignment: .leading, spacing: 8) {
                Text("Total Cost")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(formatCurrency(viewModel.totalFleetCost))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Total Cost: \(formatCurrency(viewModel.totalFleetCost))")
            .accessibilityIdentifier("kpi_total_cost")
            
            // Total Distance
            VStack(alignment: .leading, spacing: 8) {
                Text("Distance")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(Int(viewModel.totalDistance)) km")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Total Distance: \(Int(viewModel.totalDistance)) kilometers")
            .accessibilityIdentifier("kpi_total_distance")
            
            // Efficiency
            VStack(alignment: .leading, spacing: 8) {
                Text("Efficiency")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(String(format: "%.1f km/L", viewModel.fleetEfficiency))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.appEmerald)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Efficiency: \(String(format: "%.1f", viewModel.fleetEfficiency)) kilometers per liter")
            .accessibilityIdentifier("kpi_efficiency")
        }
    }
    
    // MARK: - Charts
    
    private var costTrendChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cost Trends (6 Months)")
                .font(.headline)
                .foregroundColor(.white)
            
            Chart {
                ForEach(viewModel.monthlyData) { data in
                    BarMark(
                        x: .value("Month", data.monthName),
                        y: .value("Cost", data.fuelCost)
                    )
                    .foregroundStyle(Color.orange)
                    .annotation(position: .overlay) {
                        Text("Fuel")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    BarMark(
                        x: .value("Month", data.monthName),
                        y: .value("Cost", data.maintenanceCost)
                    )
                    .foregroundStyle(Color.blue)
                }
            }
            .chartForegroundStyleScale([
                "Fuel": Color.orange,
                "Maintenance": Color.blue
            ])
            .frame(height: 250)
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cost Trends chart for the last 6 months. Showing fuel and maintenance costs.")
        .accessibilityIdentifier("analytics_cost_trends_chart")
    }
    
    private var distanceTrendChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fleet Mileage")
                .font(.headline)
                .foregroundColor(.white)
            
            Chart {
                ForEach(viewModel.monthlyData) { data in
                    LineMark(
                        x: .value("Month", data.monthName),
                        y: .value("Distance", data.totalDistance)
                    )
                    .foregroundStyle(Color.appEmerald)
                    .symbol(by: .value("Month", data.monthName))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Month", data.monthName),
                        y: .value("Distance", data.totalDistance)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appEmerald.opacity(0.3), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fleet Mileage chart showing distance trends.")
        .accessibilityIdentifier("analytics_mileage_chart")
    }
    
    private var vehicleCostDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cost by Vehicle Type")
                .font(.headline)
                .foregroundColor(.white)
            
            Chart {
                ForEach(viewModel.vehicleCostData) { data in
                    BarMark(
                        x: .value("Cost", data.cost),
                        y: .value("Type", data.vehicleType)
                    )
                    .foregroundStyle(data.color)
                    .annotation(position: .trailing) {
                        Text(formatCurrency(data.cost))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cost by Vehicle Type chart.")
        .accessibilityIdentifier("analytics_cost_distribution_chart")
    }
    
    // MARK: - Helpers
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR" // Or locale specific
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "₹0"
    }
}

// MARK: - Preview
struct FleetManagerAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        FleetManagerAnalyticsView()
            .preferredColorScheme(.dark)
    }
}
