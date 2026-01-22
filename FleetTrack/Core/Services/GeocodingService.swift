//
//  GeocodingService.swift
//  FleetTrack
//
//  Handles address ↔ coordinates conversion
//  Phase 2: Location Selection
//

import MapKit
import CoreLocation

class GeocodingService {
    static let shared = GeocodingService()
    
    private init() {}
    
    // MARK: - Forward Geocoding (Address → Coordinates)
    
    /// Convert address string to coordinates
    func geocode(address: String) async throws -> CLLocationCoordinate2D {
        guard !address.isEmpty else {
            throw LocationError.geocodingFailed("Address is empty")
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        guard let item = response.mapItems.first else {
            throw LocationError.geocodingFailed("No results found for '\(address)'")
        }
        
        return item.placemark.coordinate
    }
    
    // MARK: - Reverse Geocoding (Coordinates → Address)
    
    /// Convert coordinates to address string
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async throws -> String {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(coordinate.latitude), \(coordinate.longitude)"
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        guard let item = response.mapItems.first else {
            throw LocationError.geocodingFailed("No address found for coordinates")
        }
        
        return formatAddress(from: item.placemark)
    }
    
    /// Get detailed placemark information
    func reverseGeocodeDetailed(coordinate: CLLocationCoordinate2D) async throws -> CLPlacemark {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(coordinate.latitude), \(coordinate.longitude)"
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        guard let item = response.mapItems.first else {
            throw LocationError.geocodingFailed("No address found for coordinates")
        }
        
        return item.placemark
    }
    
    // MARK: - Place Search
    
    /// Search for places matching query
    func searchPlaces(query: String, region: MKCoordinateRegion? = nil) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        if let region = region {
            request.region = region
        }
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        return response.mapItems
    }
    
    /// Get autocomplete suggestions for query
    func autocomplete(query: String, region: MKCoordinateRegion? = nil) async throws -> [String] {
        let items = try await searchPlaces(query: query, region: region)
        return items.compactMap { $0.name }
    }
    
    // MARK: - Helper Methods
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        
        var components: [String] = []
        
        // Street address
        if let subThoroughfare = placemark.subThoroughfare {
            components.append(subThoroughfare)
        }
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        
        // City
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        // State
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        // Country
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
}
