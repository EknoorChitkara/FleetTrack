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
    
    private let geocoder = CLGeocoder()
    
    private init() {}
    
    // MARK: - Forward Geocoding (Address → Coordinates)
    
    /// Convert address string to coordinates
    func geocode(address: String) async throws -> CLLocationCoordinate2D {
        guard !address.isEmpty else {
            throw LocationError.geocodingFailed("Address is empty")
        }
        
        // Suppress deprecation warning - iOS 26.0 replacement API is not yet stable
        let placemarks = try await geocoder.geocodeAddressString(address)
        
        guard let location = placemarks.first?.location else {
            throw LocationError.geocodingFailed("No results found for '\(address)'")
        }
        
        return location.coordinate
    }
    
    // MARK: - Reverse Geocoding (Coordinates → Address)
    
    /// Convert coordinates to address string
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async throws -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Suppress deprecation warning - iOS 26.0 replacement API is not yet stable
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        guard let placemark = placemarks.first else {
            throw LocationError.geocodingFailed("No address found for coordinates")
        }
        
        return formatAddress(from: placemark)
    }
    
    /// Get detailed placemark information
    func reverseGeocodeDetailed(coordinate: CLLocationCoordinate2D) async throws -> CLPlacemark {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Suppress deprecation warning - iOS 26.0 replacement API is not yet stable
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        guard let placemark = placemarks.first else {
            throw LocationError.geocodingFailed("No address found for coordinates")
        }
        
        return placemark
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
