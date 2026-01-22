//
//  LocationSearchView.swift
//  FleetTrack
//
//  Full-screen location search with autocomplete
//

import SwiftUI
import MapKit

struct LocationSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: LocationSearchViewModel
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var selectedAddress: String
    
    let searchType: LocationSearchType
    
    init(selectedLocation: Binding<CLLocationCoordinate2D?>,
         selectedAddress: Binding<String>,
         searchType: LocationSearchType,
         currentRegion: MKCoordinateRegion) {
        self._selectedLocation = selectedLocation
        self._selectedAddress = selectedAddress
        self.searchType = searchType
        _viewModel = StateObject(wrappedValue: LocationSearchViewModel(
            searchType: searchType,
            currentRegion: currentRegion
        ))
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with search bar
                header
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Use Current Location button
                        useCurrentLocationButton
                        
                        // Recent Searches
                        if !viewModel.recentSearches.isEmpty && viewModel.searchQuery.isEmpty {
                            recentSearchesSection
                        }
                        
                        // Search Results
                        if !viewModel.searchQuery.isEmpty {
                            searchResultsSection
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: viewModel.selectedResult) { result in
            if let result = result {
                selectedLocation = result.coordinate
                selectedAddress = result.fullAddress
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Back button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                }
                .accessibilityLabel("Back")
                .accessibilityIdentifier("location_search_back_button")
                
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.appSecondaryText)
                    
                    TextField("Search for a place or address", text: $viewModel.searchQuery)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: {
                            viewModel.searchQuery = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.appSecondaryText)
                        }
                        .accessibilityLabel("Clear search")
                        .accessibilityIdentifier("location_search_clear_button")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.appCardBackground)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .padding(.bottom, 8)
        .background(Color.appBackground)
    }
    
    // MARK: - Use Current Location
    
    private var useCurrentLocationButton: some View {
        Button(action: {
            Task {
                await viewModel.useCurrentLocation()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.appEmerald)
                
                Text("Use Current Location")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.appSecondaryText)
            }
            .padding()
            .cornerRadius(12)
        }
        .accessibilityLabel("Use Current Location")
        .accessibilityHint("Uses your current device location as the search result")
        .accessibilityIdentifier("location_search_current_location_button")
    }
    
    // MARK: - Recent Searches
    
    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Searches")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appSecondaryText)
                    .textCase(.uppercase)
                
                Spacer()
                
                if !viewModel.recentSearches.isEmpty {
                    Button(action: {
                        viewModel.clearRecentSearches()
                    }) {
                        Text("Clear All")
                            .font(.system(size: 13))
                            .foregroundColor(.appEmerald)
                    }
                    .accessibilityLabel("Clear recent searches")
                    .accessibilityIdentifier("location_search_clear_recents_button")
                }
            }
            
            ForEach(viewModel.recentSearches) { result in
                locationRow(result: result, icon: "clock", iconColor: .appSecondaryText)
            }
        }
    }
    
    // MARK: - Search Results
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isSearching {
                // Loading state
                ForEach(0..<3, id: \.self) { _ in
                    skeletonRow
                }
            } else if viewModel.searchResults.isEmpty {
                // Empty state
                emptyState
            } else {
                // Results header
                Text("Search Results")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appSecondaryText)
                    .textCase(.uppercase)
                
                ForEach(viewModel.searchResults) { result in
                    let pinColor = searchType == .pickup ? Color.green : Color(hex: "F9D854")
                    locationRow(result: result, icon: "mappin.circle.fill", iconColor: pinColor)
                }
            }
        }
    }
    
    // MARK: - Location Row
    
    private func locationRow(result: LocationSearchResult, icon: String, iconColor: Color) -> some View {
        Button(action: {
            viewModel.selectResult(result)
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(result.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.appSecondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.appSecondaryText)
            }
            .padding()
            .background(Color.appCardBackground)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(result.title), \(result.subtitle)")
        .accessibilityHint("Double tap to select this location")
        .accessibilityIdentifier("location_search_result_\(result.id.uuidString.prefix(8))")
    }
    
    // MARK: - Loading Skeleton
    
    private var skeletonRow: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 14)
                    .frame(width: 200)
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.appSecondaryText)
            
            Text("No locations found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Try a different search")
                .font(.system(size: 14))
                .foregroundColor(.appSecondaryText)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}
