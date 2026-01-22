//
//  LocationSearchService.swift
//  FleetTrack
//
//  Location search with autocomplete using MKLocalSearchCompleter
//

import Foundation
import MapKit
import Combine

// MARK: - Location Search Result

struct LocationSearchResult: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let fullAddress: String
    
    init(id: UUID = UUID(), title: String, subtitle: String, coordinate: CLLocationCoordinate2D, fullAddress: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.fullAddress = fullAddress
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, fullAddress
        case latitude, longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        fullAddress = try container.decode(String.self, forKey: .fullAddress)
        let lat = try container.decode(Double.self, forKey: .latitude)
        let lon = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(subtitle, forKey: .subtitle)
        try container.encode(fullAddress, forKey: .fullAddress)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
    
    // Equatable conformance
    static func == (lhs: LocationSearchResult, rhs: LocationSearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Location Search Service

@MainActor
class LocationSearchService: NSObject, ObservableObject {
    static let shared = LocationSearchService()
    
    private let completer = MKLocalSearchCompleter()
    private var currentTask: Task<Void, Never>?
    
    @Published var completions: [MKLocalSearchCompletion] = []
    
    private override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }
    
    // MARK: - Search Methods
    
    func search(query: String, region: MKCoordinateRegion) async -> [LocationSearchResult] {
        // Cancel any ongoing task
        currentTask?.cancel()
        
        guard !query.isEmpty else {
            return []
        }
        
        // Set search region for better results
        completer.region = region
        
        return await withCheckedContinuation { continuation in
            currentTask = Task {
                // Update query (triggers completerDidUpdateResults via delegate)
                completer.queryFragment = query
                
                // Wait a bit for completions to update
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                
                guard !Task.isCancelled else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Start a timeout task
                let timeoutTask = Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds timeout
                    if !Task.isCancelled {
                        print("Search timed out")
                        return true
                    }
                    return false
                }
                
                // Convert completions to results with coordinates in parallel
                let results = await withTaskGroup(of: LocationSearchResult?.self) { group -> [LocationSearchResult] in
                    for completion in completions.prefix(10) {
                        group.addTask {
                            return await self.resolveCompletion(completion)
                        }
                    }
                    
                    var resolvedResults: [LocationSearchResult] = []
                    for await result in group {
                        if let result = result {
                            resolvedResults.append(result)
                        }
                        
                        // If timeout occurred, stop processing
                        if Task.isCancelled { break }
                    }
                    return resolvedResults
                }
                
                timeoutTask.cancel()
                continuation.resume(returning: results)
            }
        }
    }
    
    private func resolveCompletion(_ completion: MKLocalSearchCompletion) async -> LocationSearchResult? {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        do {
            let response = try await search.start()
            
            guard let item = response.mapItems.first else {
                return nil
            }
            
            let coordinate = item.placemark.coordinate
            let fullAddress = formatAddress(from: item.placemark)
            
            return LocationSearchResult(
                title: completion.title,
                subtitle: completion.subtitle,
                coordinate: coordinate,
                fullAddress: fullAddress
            )
        } catch {
            print("Failed to resolve completion: \(error)")
            return nil
        }
    }
    
    // MARK: - Current Location
    
    func getCurrentLocation() async -> (coordinate: CLLocationCoordinate2D, address: String)? {
        let locationManager = CLLocationManager()
        
        // Check authorization
        let status = locationManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            return nil
        }
        
        // Get current location
        guard let location = locationManager.location else {
            return nil
        }
        
        // Reverse geocode
        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            guard let item = response.mapItems.first else {
                return nil
            }
            
            let address = formatAddress(from: item.placemark)
            
            return (coordinate: location.coordinate, address: address)
        } catch {
            print("Reverse geocoding failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Recent Searches
    
    private let recentSearchesKey = "RecentLocationSearches"
    private let maxRecentSearches = 10
    
    func getRecentSearches() -> [LocationSearchResult] {
        guard let data = UserDefaults.standard.data(forKey: recentSearchesKey),
              let searches = try? JSONDecoder().decode([LocationSearchResult].self, from: data) else {
            return []
        }
        return Array(searches.prefix(5)) // Return max 5 for UI
    }
    
    func saveRecentSearch(_ result: LocationSearchResult) {
        var recent = getRecentSearches()
        
        // Remove duplicate if exists (by coordinate proximity)
        recent.removeAll { existingResult in
            let distance = self.distance(from: existingResult.coordinate, to: result.coordinate)
            return distance < 100 // Within 100 meters
        }
        
        // Add to beginning
        recent.insert(result, at: 0)
        
        // Keep only max items
        recent = Array(recent.prefix(maxRecentSearches))
        
        // Save
        if let data = try? JSONEncoder().encode(recent) {
            UserDefaults.standard.set(data, forKey: recentSearchesKey)
        }
    }
    
    func clearRecentSearches() {
        UserDefaults.standard.removeObject(forKey: recentSearchesKey)
    }
    
    // MARK: - Helpers
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        
        var components: [String] = []
        
        if let name = placemark.name {
            components.append(name)
        }
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        return components.joined(separator: ", ")
    }
    
    private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationSearchService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.completions = completer.results
        }
    }
    
    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Location search completer error: \(error)")
    }
}
