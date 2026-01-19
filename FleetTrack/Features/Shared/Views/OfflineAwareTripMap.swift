//
//  OfflineAwareTripMap.swift
//  FleetTrack
//
//  Wrapper that adds offline route support to UnifiedTripMap
//

import SwiftUI
import MapKit
import SwiftData

/// A wrapper view that provides offline route fallback for UnifiedTripMap
struct OfflineAwareTripMap<Provider: TripLocationProvider>: View {
    let trip: Trip
    @ObservedObject var provider: Provider
    @ObservedObject var offlineManager = OfflineSyncManager.shared
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var routePolyline: MKPolyline?
    @State private var isLoadingRoute: Bool = false
    @State private var isUsingCachedRoute: Bool = false
    @State private var isOffRoute: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            UnifiedTripMap(
                trip: trip,
                provider: provider,
                routePolyline: routePolyline,
                isOffRoute: isOffRoute
            )
            
            // Offline indicator
            if !offlineManager.isOnline {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                    Text("Offline Mode")
                    if isUsingCachedRoute {
                        Text("• Using Cached Route")
                            .font(.caption)
                    }
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange)
                .cornerRadius(16)
                .padding(.top, 8)
            }
        }
        .onAppear {
            loadRoute()
        }
        .onChange(of: offlineManager.isOnline) { _, isOnline in
            if isOnline && isUsingCachedRoute {
                // Retry fetching fresh route when back online
                loadRoute()
            }
        }
    }
    
    private func loadRoute() {
        guard routePolyline == nil else { return }
        isLoadingRoute = true
        
        Task {
            // Try to calculate route from API first
            if offlineManager.isOnline {
                await loadRouteFromNetwork()
            } else {
                await loadRouteFromCache()
            }
            
            isLoadingRoute = false
        }
    }
    
    @MainActor
    private func loadRouteFromNetwork() async {
        guard let startLat = trip.startLat,
              let startLong = trip.startLong,
              let endLat = trip.endLat,
              let endLong = trip.endLong else {
            return
        }
        
        let start = CLLocationCoordinate2D(latitude: startLat, longitude: startLong)
        let end = CLLocationCoordinate2D(latitude: endLat, longitude: endLong)
        
        do {
            let result = try await RouteCalculationService.shared.calculateRoute(from: start, to: end)
            routePolyline = result.polyline
            isUsingCachedRoute = false
            
            // Cache the route for offline use
            RouteCalculationService.shared.cacheRoute(tripId: trip.id, route: result, modelContext: modelContext)
            
        } catch {
            print("❌ Failed to calculate route: \(error)")
            // Fallback to cache
            await loadRouteFromCache()
        }
    }
    
    @MainActor
    private func loadRouteFromCache() async {
        if let cached = RouteCalculationService.shared.loadCachedRoute(tripId: trip.id, modelContext: modelContext) {
            let coordinates = cached.decodeCoordinates()
            if !coordinates.isEmpty {
                routePolyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                isUsingCachedRoute = true
                print("📦 Using cached route with \(coordinates.count) points")
            }
        }
    }
}

#Preview {
    // Preview requires mock data
    Text("OfflineAwareTripMap Preview")
}
