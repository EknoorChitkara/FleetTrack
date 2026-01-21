//
//  DriverTripsView.swift
//  FleetTrack
//
//  Shows driver's assigned trips with ability to view on map and start trip
//

import SwiftUI
import Supabase

struct DriverTripsView: View {
    @State private var trips: [Trip] = []
    @State private var isLoading = true
    @State private var selectedFilter: TripFilter = .upcoming
    @State private var navigationPath = NavigationPath()
    
    enum TripFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case ongoing = "Ongoing"
        case completed = "Completed"
    }
    
    var filteredTrips: [Trip] {
        switch selectedFilter {
        case .upcoming:
            return trips.filter { $0.status == .scheduled }
        case .ongoing:
            return trips.filter { $0.status == .ongoing }
        case .completed:
            return trips.filter { $0.status == .completed }
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("My Trips")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        
                        Button {
                            Task { await loadTrips() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                                .foregroundColor(.appEmerald)
                        }
                        .accessibilityLabel("Refresh Trips")
                        .accessibilityIdentifier("driver_trips_refresh_button")
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Filter tabs
                    HStack(spacing: 0) {
                        ForEach(TripFilter.allCases, id: \.self) { filter in
                            Button {
                                withAnimation { selectedFilter = filter }
                            } label: {
                                VStack(spacing: 8) {
                                    Text(filter.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(selectedFilter == filter ? .bold : .regular)
                                        .foregroundColor(selectedFilter == filter ? .white : .appSecondaryText)
                                    
                                    Rectangle()
                                        .fill(selectedFilter == filter ? Color.appEmerald : Color.clear)
                                        .frame(height: 3)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(filter.rawValue)
                            .accessibilityAddTraits(selectedFilter == filter ? [.isSelected, .isButton] : [.isButton])
                        }
                    }
                    .padding(.top, 16)
                    
                    // Content
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.appEmerald)
                        Spacer()
                    } else if filteredTrips.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "road.lanes")
                                .font(.system(size: 60))
                                .foregroundColor(.appSecondaryText.opacity(0.5))
                            
                            Text("No \(selectedFilter.rawValue.lowercased()) trips")
                                .font(.headline)
                                .foregroundColor(.appSecondaryText)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredTrips) { trip in
                                    NavigationLink(value: trip) {
                                        DriverTripCardView(trip: trip)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationDestination(for: Trip.self) { trip in
                TripMapView(trip: trip)
            }
        }
        .task {
            await loadTrips()
        }
    }
    
    // MARK: - Load Trips
    
    private func loadTrips() async {
        isLoading = true
        
        do {
            // Get current user's driver ID
            guard let session = try? await supabase.auth.session else {
                print("❌ No session found")
                isLoading = false
                return
            }
            
            print("✅ Session active for: \(session.user.email ?? "unknown")")
            
            // First get driver record for this user
            let drivers: [FMDriver] = try await supabase
                .from("drivers")
                .select()
                .eq("user_id", value: session.user.id)
                .execute()
                .value
            
            guard let driver = drivers.first else {
                print("⚠️ No driver record found for user")
                trips = Trip.mockTrips
                isLoading = false
                return
            }
            
            print("✅ Found driver: \(driver.fullName ?? "unknown") with id: \(driver.id)")
            
            // Fetch trips for this driver
            trips = try await supabase
                .from("trips")
                .select()
                .eq("driver_id", value: driver.id)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("✅ Loaded \(trips.count) trips")
            
            // Debug print first trip coordinates
            if let first = trips.first {
                print("   First trip: \(first.startAddress ?? "?") -> \(first.endAddress ?? "?")")
                print("   Coords: (\(first.startLat ?? 0), \(first.startLong ?? 0)) -> (\(first.endLat ?? 0), \(first.endLong ?? 0))")
            }
            
        } catch {
            print("❌ Error loading trips: \(error)")
            trips = Trip.mockTrips
        }
        
        isLoading = false
    }
}

// MARK: - Trip Card View

struct DriverTripCardView: View {
    let trip: Trip
    
    var statusColor: Color {
        switch trip.status {
        case .scheduled: return .blue
        case .ongoing: return .orange
        case .completed: return .green
        case .cancelled: return .red
        case .none: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(trip.status?.rawValue ?? "Unknown")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .cornerRadius(8)
                
                Spacer()
                
                if let distance = trip.distance {
                    HStack(spacing: 4) {
                        Image(systemName: "road.lanes")
                        Text(String(format: "%.1f km", distance))
                    }
                    .font(.caption)
                    .foregroundColor(.appSecondaryText)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.appSecondaryText)
            }
            
            // Route
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                    Rectangle().fill(Color.appSecondaryText.opacity(0.3)).frame(width: 2, height: 30)
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PICKUP").font(.caption2).foregroundColor(.appSecondaryText)
                        Text(trip.startAddress ?? "Unknown location")
                            .font(.subheadline).fontWeight(.medium).foregroundColor(.white).lineLimit(1)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DROPOFF").font(.caption2).foregroundColor(.appSecondaryText)
                        Text(trip.endAddress ?? "Unknown location")
                            .font(.subheadline).fontWeight(.medium).foregroundColor(.white).lineLimit(1)
                    }
                }
            }
            
            // Footer
            if let purpose = trip.purpose, !purpose.isEmpty {
                HStack {
                    Image(systemName: "note.text").font(.caption)
                    Text(purpose).font(.caption)
                }
                .foregroundColor(.appSecondaryText)
            }
            
            if let startTime = trip.startTime {
                HStack {
                    Image(systemName: "calendar.badge.clock").font(.caption)
                    Text(startTime.formatted(date: .abbreviated, time: .shortened)).font(.caption)
                }
                .foregroundColor(.appEmerald)
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Trip Status: \(trip.status?.rawValue ?? "Unknown"). \(trip.startAddress ?? "Unknown Start") to \(trip.endAddress ?? "Unknown Destination"). \(trip.startTime != nil ? "Date: \(trip.startTime!.formatted(date: .abbreviated, time: .shortened))" : "")")
        .accessibilityHint("Double tap to view trip details")
        .accessibilityIdentifier("driver_trip_card_\(trip.id.uuidString.prefix(8))")
    }
}

#Preview {
    DriverTripsView()
}
