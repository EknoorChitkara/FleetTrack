//
//  DriverTripsView.swift
//  FleetTrack
//
<<<<<<< HEAD
//  Shows driver's assigned trips with ability to view on map and start trip
=======
//  Created for Driver
>>>>>>> 7ebedc4 (error)
//

import SwiftUI
import Supabase

struct DriverTripsView: View {
<<<<<<< HEAD
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
=======
    @StateObject private var viewModel: DriverTripsViewModel
    @State private var selectedSegment = 0 // 0: Upcoming, 1: History
    
    // Mock user ID for now
    init() {
        _viewModel = StateObject(wrappedValue: DriverTripsViewModel(driverId: User.mockDriver.id))
    }
    
    var body: some View {
        NavigationView {
>>>>>>> 7ebedc4 (error)
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
<<<<<<< HEAD
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
=======
                        Text("Trips")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .padding(.top, 20)
                    
                    // Custom Segment Control
                    HStack(spacing: 0) {
                        SegmentButton(title: "Upcoming", isSelected: selectedSegment == 0) {
                            withAnimation { selectedSegment = 0 }
                        }
                        SegmentButton(title: "History", isSelected: selectedSegment == 1) {
                            withAnimation { selectedSegment = 1 }
                        }
                    }
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    
                    // List Content
                    ScrollView {
                        if viewModel.isLoading {
                            ProgressView().tint(.white).padding(.top, 50)
                        } else {
                            LazyVStack(spacing: 16) {
                                let trips = selectedSegment == 0 ? viewModel.upcomingTrips : viewModel.historyTrips
                                
                                if trips.isEmpty {
                                    EmptyStateView(tab: selectedSegment)
                                } else {
                                    ForEach(trips) { trip in
                                        NavigationLink(destination: TripDetailsContainer(trip: trip, viewModel: viewModel)) {
                                            TripCard(trip: trip)
                                        }
                                    }
>>>>>>> 7ebedc4 (error)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
<<<<<<< HEAD
            .navigationDestination(for: Trip.self) { trip in
                TripMapView(trip: trip)
=======
            .navigationBarHidden(true)
            .task {
                await viewModel.loadTrips()
>>>>>>> 7ebedc4 (error)
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
    }
}

// Helper Container to route to correct view based on status
struct TripDetailsContainer: View {
    let trip: Trip
    @ObservedObject var viewModel: DriverTripsViewModel
    
    var body: some View {
        if trip.status == .ongoing {
            ActiveTripView(trip: trip, viewModel: viewModel)
        } else {
            TripDetailsView(trip: trip, viewModel: viewModel)
        }
    }
}

struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? .black : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.appEmerald : Color.clear)
                .cornerRadius(12)
        }
    }
}

struct EmptyStateView: View {
    let tab: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: tab == 0 ? "car.circle" : "clock.arrow.circlepath")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text(tab == 0 ? "No upcoming trips" : "No trip history")
                .foregroundColor(.gray)
                .font(.headline)
        }
        .padding(.top, 50)
    }
}

struct TripCard: View {
    let trip: Trip
    
    var statusColor: Color {
        switch trip.status {
        case .scheduled: return .white.opacity(0.2)
        case .ongoing: return .appEmerald.opacity(0.2)
        case .completed: return .appEmerald
        case .cancelled: return .red
        default: return .gray
        }
    }
    
    var statusTextColor: Color {
        switch trip.status {
        case .ongoing: return .appEmerald
        case .completed: return .black
        default: return .white
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TRP-\(trip.id.uuidString.prefix(4).uppercased())") // Using ID prefix mock
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(trip.startTime?.formatted(date: .omitted, time: .shortened) ?? "TBD")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    if let dist = trip.formattedDistance {
                        Text(dist)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Status Badge
            Text(trip.status?.rawValue ?? "Unknown")
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor)
                .foregroundColor(statusTextColor)
                .cornerRadius(4)
            
            // Route
            VStack(alignment: .leading, spacing: 0) { // Timeline style
                HStack(alignment: .top) {
                    Circle().fill(Color.appEmerald).frame(width: 8, height: 8).padding(.top, 4)
                    VStack(alignment: .leading) {
                        Text("Pickup")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(trip.pickupLocationName ?? trip.startAddress ?? "Unknown")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 8)
                }
                
                Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 1, height: 20).padding(.leading, 3.5)
                
                HStack(alignment: .top) {
                    Circle().fill(Color.red).frame(width: 8, height: 8).padding(.top, 4)
                    VStack(alignment: .leading) {
                        Text("Drop-off")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(trip.dropoffLocationName ?? trip.endAddress ?? "Unknown")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 8)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
}

#Preview {
    DriverTripsView()
}
