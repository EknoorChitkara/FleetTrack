//
//  LocationSearchViewModel.swift
//  FleetTrack
//
//  ViewModel for location search with autocomplete
//

import Foundation
import SwiftUI
import MapKit
import Combine

enum LocationSearchType {
    case pickup
    case dropoff
}

@MainActor
class LocationSearchViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [LocationSearchResult] = []
    @Published var recentSearches: [LocationSearchResult] = []
    @Published var isSearching: Bool = false
    @Published var selectedResult: LocationSearchResult?
    
    private let searchService = LocationSearchService.shared
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    let searchType: LocationSearchType
    let currentRegion: MKCoordinateRegion
    
    init(searchType: LocationSearchType, currentRegion: MKCoordinateRegion) {
        self.searchType = searchType
        self.currentRegion = currentRegion
        
        loadRecentSearches()
        setupSearchObserver()
    }
    
    private func setupSearchObserver() {
        // Debounce search query
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self = self else { return }
                Task {
                    await self.performSearch(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(query: String) async {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        searchTask = Task {
            let results = await searchService.search(query: query, region: currentRegion)
            
            guard !Task.isCancelled else {
                return
            }
            
            self.searchResults = results
            self.isSearching = false
        }
    }
    
    func loadRecentSearches() {
        recentSearches = searchService.getRecentSearches()
    }
    
    func selectResult(_ result: LocationSearchResult) {
        selectedResult = result
        searchService.saveRecentSearch(result)
    }
    
    func useCurrentLocation() async {
        isSearching = true
        
        if let location = await searchService.getCurrentLocation() {
            let result = LocationSearchResult(
                title: "Current Location",
                subtitle: location.address,
                coordinate: location.coordinate,
                fullAddress: location.address
            )
            selectedResult = result
            searchService.saveRecentSearch(result)
        }
        
        isSearching = false
    }
    
    func clearRecentSearches() {
        searchService.clearRecentSearches()
        recentSearches = []
    }
}
